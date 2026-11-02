# Book cover

`cover.png` (1200 x 1575) is the book's cover, set as `cover-image` in
`../index.Rmd`. The owl is original artwork drawn in code.

To change it:

1. Edit `make_owl.py` (the engraving-style owl) or `cover.html` (layout,
   title, colours).
2. Rebuild the owl and copy the logo next to the layout:

   ```sh
   python3 make_owl.py > owl.svg
   cp ../../man/figures/logo.png .
   ```

3. Open `cover.html` in a browser at 1200 x 1575 pixels and take a
   screenshot, for example with Playwright or Chrome's device toolbar, and
   save it as `cover.png`.

`owl.svg` and the copied `logo.png` are build intermediates and are not
committed.
