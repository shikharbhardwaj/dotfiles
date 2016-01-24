##Project Name

A dummy project directory for C++ projects.

##Directory structure

 - *bin*: The output executables go here, both for the app and for any tests and spikes.
 - *build*: This folder contains all object files, and is removed on a clean.
 - *doc*: Any notes, like my assembly notes and configuration files, are here.
 - *include*: All project header files. All necessary third-party header files that do not exist under /usr/local/include are also placed here.
 - *lib*: Any libs that get compiled by the project, third party or any needed in development. Prior to deployment, third party libraries get moved to /usr/local/lib where they belong, leaving the project clean enough to compile on our Linux deployment servers. I really use this to test different library versions than the standard.
 - *spike*: I often write smaller classes or files to test technologies or ideas, and keep them around for future reference. They go here, where they do not dilute the real application’s files, but can still be found later.
 - *src*: The application and only the application’s source files.
 - *test*: All test code files. You do write tests, no?

##Contributing


##Inspiration


##Dev environment

