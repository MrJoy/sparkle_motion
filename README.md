# Sparkle Motion

Generative event lighting system using Philips Hue and Novation Launchpad.

## Wait, What?

This begins its life as a system I am using to make a nifty lighting system for my wedding reception.

It's designed to use multiple Philips Hue Bridges, with about 6-7 lights per bridge in the main "simulation", and physically arranged in a line -- with a handful of other bulbs for the dance floor, and accent lighting.

While it can be made to use much less, the example configuration assumes:

* 4 Philips Hue Bridges
* 6-7 "Main" lights *per bridge*
* 1 Dance-Floor light *per bridge*
* 9 Accent lights in total.

Control of the system is currently done with a Novation Launchpad Mark 2.  (The Mark 1 will *not* work -- if you have RGB LEDs, you should be good to go.  If you only have red+green -- no go, sorry.)


### Ok...  But What does it DO?

It [does this](https://youtu.be/uHnz6tYhiWE).

1. It swirls the hue of the lighting through a predefined sequence of colors.
1. It generates a Perlin noise pattern to control the brightness.
    * ... and lets you modulate that for different regions of the room using controls on the Novation Launchpad.
1. It lets you desaturate the lights in a region of the room so photographers can get good pictures (blue-ish light on skin is terrible for photography).
    * ... again, controlled from the Novation Launchpad.
1. It lets you spotlight one area of the lights.  Handy if, for example, someone wants to give a toast.

You can configure:

1. How many lights across how many bridges there are, and how they are physically laid out.
1. What controls, and where, exist on the Novation Launchpad.
1. How many positions they have, and what values those result in.
1. How the noise pattern is generated and modified.
1. What colors swirl around, and in what pattern.

### So It's Only For Your Wedding?

It started out that way, but the code is increasingly becoming generalized.

My end goal has become:

1. Ability to use other control sources:
    * Microphones (FFT to get loudness) as secondary driver of control values.
    * Numark Orbit (on-the-go control of some parameters).
    * Other?  OSC-controls, etc perhaps?
1. Ability to control other types of lights.  Notably, DMX.
1. Ability to define a DAG of operations to generate the lighting pattern.
    * Visual debugging tools to help produce coherent and impressive lighting effects in the face of rate limiting on Zigbee networks.
1. 2D positioning of lights in relation to a 3D simulation (2 spatial, plus time) -- or possibly even 4D (3 spatial + time).
1. Ability to design "screens" for control surfaces to bind arbitrary widgets to arbitrary parameters.

### What Do I Need to Use it Right Now?

1. At least 1 Philips Hue Bridge.
1. At least a few Philips Hue bulbs -- ideally colored, but limited functionality is possible with the Lux bulbs.
    * Actually, any lights you can address from the Philips Hue Bridge will work, but colored is important.
1. A Novation Launchpad Mark 2 -- *absolutely not* a Mark 1.

I strongly suggest not trying to use more than about 7 bulbs per bridge.


## Installation

After cloning this repo, run:

```bash
brew install portmidi fftw
gem install sparkle_motion
sm-discover # Find all available bridges using SSDP.
# Create `config.yml`, and register the username(s) in it with the relevant bridges.
# You probably want to start with the one in this project's source repo as a baseline.
sm-mark-lights # Ensure your lights are physically arranged properly.
sm-on # Switch all the lights on, and set color to expected base state.
sparkle-motion # Run the simulation.
```

__TODO: Document how to register user with hub(s).__


## Usage

* `bin/sm-discover`: Discover all Philips Hue bridges on your network.
* `bin/sm-mark-lights`: Mark the lights distinctively to help ensure they're physically arranged properly.
* `bin/sm-off`: Turn all configured lights off.
* `bin/sm-on`: Turn all configured lights on, and set them to the base color.
* `bin/sm-simulate`: Run the effect system directly.  You probably want `sparkle-motion` instead.
* `bin/sparkle-motion`: Runs the effect system with configuration settings for debugging, and restarts it if the kick-in-the-head button is pressed.  See source for details.

## Using the Code

* `examples/tictactoe.rb`: A simple example of the Novation Launchpad widgets, and how to use/extend them.
* `tools/chunker.rb`: Helper for churning through `*.raw` files and preparing them for visualization.
* `tools/color_scale.rb`: A small playground for defining color schemes for Novation LaunchPad widgets.


## Debugging

* `bin/sm-watch-memory`: External monitor to keep an eye on the process size of `sm-simulate`.  Useful for debugging memory allocations and GC pressure.


## Configuration

__ TODO: Write me.__
