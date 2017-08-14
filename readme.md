# Sharkduino Data Analysis (Honors Project)

The goal of this project is to determine the behavior of sharks by
looking at their accelerometer and gyroscope data. This document is a
"getting started" guide for someone who has chosen, or been chosen, to
help me with this, including a version of me from the far future who
forgot that this existed.

## Setup

First, find the raw accelerometer data and move it into the repo 
directory; put it in a foldr named "Accelerometer". Then run 
`import_all.m` to generate `ACCEL.MAT`.

## What is here?

The main scripts to look at are `closeup.m` and `turning_svm.m`. The
first displays a (possibly labeled) slice of data through a variety
of means; the second tries to use the various feature files
(`feature_accel.m`, `feature_analysis.m`, ...) to generate an SVM
predictor.

SLICES.MAT contains various "data slices" - these are pieces of ACCEL.MAT,
often with an accompanying label file or description. You'll use these
when loading chunks of data via `load_accel_slice.m` or
`load_accel_slice_windowed.m`.

## What isn't here?

Due to space considerations, most of the raw data for this project
(barring the labels) is not in this repository. The raw accelerometer
data and video data are available from Dan Crear and are backed up on
both my laptop and backup hard drives.

The "Accelerometer" folder contains the raw data, and is used by the
code, at least for the purpose of transforming it into ACCEL.MAT via
`import_all.m`. The "Video" folder contains all video data, and is not
used by the code at this point.
