// HACK: Monkey-patch babel-runtime to accept non-es6 modules...
import "../common/common";
// Run the actual code. Note that if we import "common" from "main", things won't work (due to local caching)
import "./app";