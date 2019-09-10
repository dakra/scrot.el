# Simple screenshot utility for Emacs

Take screenshots with scrot (or tool specified in `scrot-command`),
upload them to imgbb and copy the url to the kill-ring.

## Usage

Just call `M-x scrot`, select your filename (which is pre-filled
with a few suggestions. Use `M-n` to select different ones)
and then select the region you want a screenshot of.

If you call `scrot` with a prefix argument (e.g. `C-u M-x scrot`)
then the image will be inserted as an org-link in the current
buffer from where you called `scrot`.
