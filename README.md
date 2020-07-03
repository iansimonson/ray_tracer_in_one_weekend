Follows [Ray Tracing in One Weekend](https://raytracing.github.io/books/RayTracingInOneWeekend.html)
using the Zig `@fieldParentPointer` to mimic virtual functions from C++.

Copies basically everything everywhere in a funtional-ish style hoping for
llvm to optimize in the background

util.random has to be initialized first. This means there's only one seed
that's generating all the random numbers but the thing is _super slow_
if you have to generate the random seed each time as it'll spend 90+% of
the run time in syscalls for random data

Outputs to ppm file, does _not_ do anything fancy like print to sdl or anything