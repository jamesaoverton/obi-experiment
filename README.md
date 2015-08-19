# OBI Experiment

This repository contains experiments using the [Ontology for Biomedical Investigations](http://obi-ontology.org) (OBI) to model scientific experiments.

- [Glucose Measurement](glucode.md)


## Setting Up

This project uses [GNU Make](http://www.gnu.org/software/make/) and standard Unix tools. If you're on a Unix or Linux system, you probably have all the requirements installed already. If you're on a Mac OS X system, you might be prompted to install [XCode](https://developer.apple.com/xcode/). If you're on Windows, then you should use [Vagrant](https://www.vagrantup.com) to run a virtual machine with a [Debian Linux](https://www.debian.org) operating system. (Even if you're using Linux or Mac OS X, Vagrant can be a good option.) The [`Vagrantfile`](Vagrantfile) will configure Vagrant for you.

Once Vagrant is installed, these commands will start the virtual machine, log in to it, and switch to the special `/vagrant` directory which is linked to the project directory on your host operating system:

    > vagrant up
    > vagrant ssh
    $ cd /vagrant

When you're done, log out and either suspend or destroy the virtual machine:

    $ exit
    > vagrant suspend
    > vagrant destroy


## Use

Clone this repository and `cd` into it:

    git clone https://github.com/jamesaoverton/obi-experiment.git
    cd obi-experiment

To build the whole project (which should be very fast), just run

    make

To remove generated files, run

    make clean

