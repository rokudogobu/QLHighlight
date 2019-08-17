
# QLHighlight

QuickLook plugin for syntax highlighting by using [highlight.js](https://highlightjs.org) and [highlightjs-line-numbers.js](https://github.com/wcoder/highlightjs-line-numbers.js/).

## Installation

Please copy or move `QLHighlight.qlgenerator` into `~/Library/QuickLook` and reload generators list by executing following command:

    $ qlmanage -r

## Settings

### File types

By default, this QuickLook plugin is enabled for following file types:

- C/C++
- Objective-C
- C#
- Swift
- Python
- Perl
- Ruby
- Shell/Bash script
- Java
- SQL
- Lua
- patch/diff
- html
- PHP
- CSS
- AppleScript

You can add/delete file type by editing `Info.plist`.

### Display styles

You can change the styles by executing following command:

    $ defaults write localhost.QLHighlight <key> -string <value>

#### style keys

The keys and default values are listed in tables below:

- for source code

  | key            | default value  |
  |:---:|:---:|
  | style          | solarized-dark |
  | font-size      | 12px           |
  | font-family    | ( not set )    |
  | line-height    | 1.25rem        |
  | tab-size       | 4              |

- for line number

  | key            | default value  |
  |:---:|:---:|
  | ln-font-family | Courier New    |
  | ln-font-size   | 0.9rem         |
  | ln-font-color  | #666           |

#### values for keys

The value of `style` is a css file name for highlight.js without extension.
You can choose one from  `QLHighlight.qlgenerator/Contents/Resources/styles` ( same as `src/styles` of hightlight.js repository ), but a css which requires external image is not recommended.

The value for other keys must be in CSS format.
Those values are copied into `<style>` of an internally generated html code.

## License

Copyright (c) 2019 rokudogobu.  
Licensed under the Apache License, Version 2.0.  
See LICENSE for details.
