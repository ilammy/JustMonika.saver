JustMonika
==========

Main screen saver bundle.

`JustMonikaView` is the principal class, start reading from there.
It’s a good idea to keep [Screen Saver Framework](https://developer.apple.com/documentation/screensaver) documentation open.
However, it does not describe everything.
Here are some things that are not really documented anywhere:

- It is possible to add a custom thumbnail for your screen saver
  by putting an image called [`thumbnail`](Resources/thumbnail@2x.png) into resources.
  However, it does not look as good as it could be because of sloppy programming in the screen saver preference pane.
