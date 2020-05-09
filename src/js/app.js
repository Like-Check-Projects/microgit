/* eslint no-console:0 */

// Rails Unobtrusive JavaScript (UJS) is *required* for links in Lucky that use DELETE, POST and PUT.
// Though it says "Rails" it actually works with any framework.
require("@rails/ujs").start();

// Turbolinks is optional. Learn more: https://github.com/turbolinks/turbolinks/
require("turbolinks").start();

require("alpinejs");

import Prism from 'prismjs';

const SimpleMDE = require("simplemde");

Prism.highlightAll();

document.addEventListener("turbolinks:load", function() {
  if(document.getElementById("simple_editor")) {
    const easymde = new SimpleMDE({ element: document.getElementById("simple_editor") });
  }
})
// If using Turbolinks, you can attach events to page load like this:
//
// document.addEventListener("turbolinks:load", function() {
//   ...
// })
