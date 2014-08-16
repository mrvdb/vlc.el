;;; vlc --- An interface to vlc from Emacs

;;; Summary:
;; Using the rc interface of vlc Emacs can control
;; media playing quite easily

;;; Commentary:

;;; Code:
(eval-when-compile
  (require 'cl))

(defgroup vlc ()
  "Interface to the videolan suite of programs"
  :group 'multimedia)

(defvar vlc-process nil
  "VideoLAN subprocess currently playing media.")

(defcustom vlc-program-name "vlc"
  "The program to use for vlc subprocesses, typically 'vlc'."
  :group 'vlc)

(defun vlc-get(item)
  "Get a process property by name"
  (process-get vlc-process item))

(defun vlc/start ()
  "Start a vlc process for control from Emacs."
  (interactive)
  (cl-block :cancel
    (when (process-live-p vlc-process)
      ;; We already have live process
      (when (and (called-interactively-p 'interactive)
		 ;; Offer to kill it
		 (not (y-or-n-p "VLC already running, should I kill it? ")))
	(cl-return-from :cancel))
      (delete-process vlc-process))
    (setf vlc-process
	  ;; Start a proces controllable by the rc interface
	  (start-process "vlc-media" nil vlc-program-name "--extraintf" "rc"))))

(defun vlc (&rest commands)
  "Send a command(-set) to a vlc subprocess.
If COMMANDS is a keyword (starts with a ':') then the
colon is stripped.  Everything else is passed verbatim."
  (if (not (processp vlc-process))
      ;;(error "Start a media file with `vlc/start' first")
      ;; Why not do this? Seems to make sense to prevent the error
      (vlc/start)
    (unless (process-live-p vlc-process)
      ;; It is a process, but it's not alive??
      (progn
	;; Were we playing something?
	(message (vlc-get :media-file))
	(vlc/start))))
  (with-temp-buffer
    (let ((standard-output (current-buffer)))
      (dolist (command commands)
	(if (keywordp command)
	    ;; ':command' found, pass on without the ':'
	    (princ (substring (symbol-name command) 1))
	  (princ command))
	(princ " "))
      (princ "\n")
      (process-send-region vlc-process (point-min) (point-max)))))

(defun vlc/play/pause ()
  "Toggle play pause on the vlc media."
  (interactive)
  (let ((play-state (vlc-get :play-state)))
    (if (eq play-state 'paused)
	(vlc/play)
      (vlc/pause))))

(defun vlc/play ()
  "Play whatever is current, if anything."
  (interactive)
  ;; Add it to the playlist
  (vlc :play)
  (setf (process-get vlc-process :play-state) 'playing))

(defun vlc/pause()
  "Pause whatever is current, if anything."
  (interactive)
  (vlc :pause)
  (setf (process-get vlc-process :play-state) 'paused))

(defun vlc/stop()
  "Stop playing"
  (vlc :stop)
  (setf (process-get vlc-process :play-state) nil))
		 
(defun vlc/add (uri)
  "Add item specified by URI to the playlist and start playing it."
  (interactive)
  (vlc :add uri))

(defun vlc/enqueue (uri)
  "Enqueue URI into the vlc play queue without switching to it.
This differs from the `vlc/add' function that it does not start
playing the item that is added to the playlist."
  (interactive)
  (vlc :enqueue uri))

(defun vlc/playlist()
  "Show items currently in playlist"
  (interactive)
  (vlc :playlist))


(provide 'vlc)
;;; vlc.el ends here
