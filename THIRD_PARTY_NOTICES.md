# Third-party notices

This file inventories third-party software included by the app, including the Swift Package Manager dependencies pinned in `Stiint.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` and JavaScript libraries bundled by Sankey. Recheck it when package pins or bundled resources change and before redistributing a build. The original Stiint source license is in [LICENSE](LICENSE).

## AcknowList 3.4.0

- Repository: <https://github.com/vtourraine/AcknowList>
- Resolved revision: `2b8be7841af2eefa0e75640d0c1a2312a1ba75be`
- License reported by the upstream project: MIT
- Upstream license file at the pinned revision: <https://github.com/vtourraine/AcknowList/blob/2b8be7841af2eefa0e75640d0c1a2312a1ba75be/LICENSE.txt>
- Bundled app resource: [`Stiint/Resources/AcknowList-LICENSE.txt`](Stiint/Resources/AcknowList-LICENSE.txt)

The checkout at the resolved revision contains this MIT notice:

```text
Copyright (c) 2015-2025 Vincent Tourraine (https://www.vtourraine.net)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## D3.js 7.9.0 (bundled by Sankey)

- Upstream project: <https://github.com/d3/d3>
- Version/license metadata: [`package.json` at v7.9.0](https://github.com/d3/d3/blob/v7.9.0/package.json) identifies version 7.9.0 and the ISC license.
- Upstream license file: [`LICENSE` at v7.9.0](https://github.com/d3/d3/blob/v7.9.0/LICENSE)
- Included file: `build/DerivedData/SourcePackages/checkouts/Sankey/Sources/Resources/d3.min.js`, supplied through the pinned Sankey 2.0.0 package resources.
- The bundled file banner identifies D3.js v7.9.0 and copyright 2010–2023 Mike Bostock. Its SHA-256 in the reviewed pinned checkout was `f2094bbf6141b359722c4fe454eb6c4b0f0e42cc10cc7af921fc158fceb86539`.
- Bundled app resource: [`Stiint/Resources/D3-LICENSE.txt`](Stiint/Resources/D3-LICENSE.txt)

The bundled file's version banner and the upstream v7.9.0 package metadata agree. The generated `dist/d3.min.js` file was not available at the upstream Git tag's raw path through the source browser, so no byte-for-byte comparison with the upstream published distribution is claimed.

The upstream v7.9.0 `LICENSE` text is:

```text
Copyright 2010-2023 Mike Bostock

Permission to use, copy, modify, and/or distribute this software for any purpose
with or without fee is hereby granted, provided that the above copyright notice
and this permission notice appear in all copies.
THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.
```

## d3-sankey 0.12.3 (bundled by Sankey)

- Upstream project: <https://github.com/d3/d3-sankey>
- Version/license metadata: [`package.json` at v0.12.3](https://github.com/d3/d3-sankey/blob/v0.12.3/package.json) identifies version 0.12.3 and the BSD-3-Clause license.
- Upstream release: [v0.12.3](https://github.com/d3/d3-sankey/releases/tag/v0.12.3)
- Upstream license file: [`LICENSE` at v0.12.3](https://github.com/d3/d3-sankey/blob/v0.12.3/LICENSE)
- Included file: `build/DerivedData/SourcePackages/checkouts/Sankey/Sources/Resources/d3-sankey.min.js`, supplied through the pinned Sankey 2.0.0 package resources.
- The bundled file banner identifies d3-sankey v0.12.3 and copyright 2019 Mike Bostock. The v0.12.3 upstream `LICENSE` notice itself says `Copyright 2015, Mike Bostock`; that license notice is reproduced verbatim below. The bundled JavaScript also retains its own banner. Its SHA-256 in the reviewed pinned checkout was `8286db5d6aa049cc6e8a546708943b79dfb4daaefb0ccf42af674ec0ee4c86be`.
- Bundled app resource: [`Stiint/Resources/D3-Sankey-LICENSE.txt`](Stiint/Resources/D3-Sankey-LICENSE.txt)

The bundled file's version banner and the upstream v0.12.3 package metadata agree. The generated `dist/d3-sankey.min.js` file was not available at the upstream Git tag's raw path through the source browser, so no byte-for-byte comparison with the upstream published distribution is claimed.

The upstream v0.12.3 `LICENSE` text is:

```text
Copyright 2015, Mike Bostock
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the author nor the names of contributors may be used to
  endorse or promote products derived from this software without specific prior
  written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

## Sankey 2.0.0

- Repository: <https://github.com/maxhumber/Sankey>
- Resolved revision: `a25843ed87bbe3f9be4d27a014b47792dcaeb3fc`
- License label on the upstream GitHub repository: BSD-2-Clause
- Upstream license file at the pinned revision: <https://github.com/maxhumber/Sankey/blob/a25843ed87bbe3f9be4d27a014b47792dcaeb3fc/LICENSE>
- Bundled app resource: [`Stiint/Resources/Sankey-LICENSE.txt`](Stiint/Resources/Sankey-LICENSE.txt)

The checkout at the resolved revision contains this BSD 2-Clause notice:

```text
BSD 2-Clause License

Copyright (c) 2022, Max Humber
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

## Original Stiint source

The upstream app code is MIT-licensed. Its existing [`LICENSE`](LICENSE) file retains the original copyright notice, `Copyright (c) 2026 Liam Wittig`. Keep that notice in copies and substantial portions of the original source.
