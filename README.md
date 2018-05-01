
### Bergt A, Urai AE, Donner TH, Schwabe L (2018) _Reading memory formation from the eyes_. bioRxiv:268490. ###
*European Journal of Neuroscience, forthcoming*

If you have any questions, open an issue or get in touch @AnneEUrai / anne.urai@gmail.com

This repository contains
```
├─ code               # all matlab code to run the analyses
├─ figures            # final publication-ready figures
├─ stimulus_materials # image and audio files that were used as stimuli
├─ data               # raw pupil and behavioral data
```


#### To rerun all analyses on the raw data, do the following:

In a0_overview.m, change mypath to the place where all the data are stored. This folder should have the following structure

```
├── behaviour
│   ├── phase1
│     ├── results           # xls files
│     ├── log               # mat files
│   ├── phase2
│     ├── results           # xls files
│     ├── log               # mat files
├── recall                  # all Bilder.csv and Worter.csv files
├── auditory                # output of auditory csv files
├── visual                  # output of visual csv files
├── pupil                   # all converted BeGaze text files, plus output of pupil preprocessing
├── figures                 # folder for results figures
```
