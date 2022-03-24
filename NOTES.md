# Notes on the DWIN display firmware/files

Useful links:

- https://imagemagick.org/script/identify.php
- https://imagemagick.org/script/command-line-options.php
- https://imagemagick.org/script/convert.php

Attempt to fix custom ICO image by stripping metadata, switching to TrueColor and removing resolution/DPI information:

```sh
convert 'CUSTOM_DATA/7/000-ICON_LOGO.jpg' -strip -type TrueColor -density 0 'CUSTOM_DATA/7/000-ICON_LOGO_new.jpg'
```

Attempt to fix custom startup logo by stripping metadata and switching from Grayscale to TrueColor:

```sh
convert 'CUSTOM_DATA/0_start.jpg' -strip -type TrueColor 'CUSTOM_DATA/0_start_new.jpg'
```

The information above was obtained with the following command, comparing the original images with the custom images:

```sh
magick identify -verbose <path to image>
```

TODO: Add automatic conversion for _all_ images to match the above?
TODO: Research/check other image properties that we could/should always set, to ensure maximum compatibility?
