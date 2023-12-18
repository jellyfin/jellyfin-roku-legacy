// MIT License

// Copyright (c) 2019 George Cook

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/* eslint-disable @typescript-eslint/no-unsafe-argument */
/* eslint-disable github/array-foreach */
/* eslint-disable @typescript-eslint/no-var-requires */
/* eslint-disable @typescript-eslint/no-require-imports */
const fs = require('fs-extra');
const path = require('path');

let componentsDir = path.join(__dirname, '..', 'components', 'roku_modules');

parseFolder(componentsDir);

let sourceDir = path.join(__dirname, '..', 'source', 'roku_modules');
parseFolder(sourceDir);

function parseFolder(sourceDir) {
    try {
        fs.readdirSync(sourceDir).forEach(file => {
            let filePath = path.join(sourceDir, file);
            let fileStats = fs.statSync(filePath);
            if (fileStats.isDirectory()) {
                parseFolder(filePath);
            } else if (filePath.endsWith('.xml')) {
                let text = fs.readFileSync(filePath, 'utf8');
                let r = /\/roku_modules\/undefined\/bslib\.brs/gim;
                text = text.replace(r, '/roku_modules/rokucommunity_bslib/bslib.brs');
                r = /\/roku_modules\/bslib\/bslib\.brs/gim;
                text = text.replace(r, '/roku_modules/rokucommunity_bslib/bslib.brs');
                r = /\/roku_modules\/undefined/gim;
                text = text.replace(r, '/roku_modules/maestro');
                fs.writeFileSync(filePath, text);
                // console.log('fixed', filePath);
            }
        });
    } catch (e) {
        console.log(e);
    }
}