# BrillouinEvaluation

**BrillouinEvaluation** is used to evaluate Brillouin microscopy data acquired by **BrillouinAcquisition** (https://github.com/BrillouinMicroscopy/BrillouinAcquisition).


## System requirements

The software requires MATLAB 2019a or higher to run.


## Installation guide

In order to install and run the software, download the provided ZIP file from the latest release, unpack the file on your PC and add the path to the folder to your MATLAB path. Then execute `BrillouinEvaluation` from within MATLAB.


## Demonstration

Datasets for demonstration are provided in the `tests/data` folder. Open the `h5` files in the `data` folder with `BrillouinEvaluation` by using `File -> Open`.


## Usage

- Open the `h5` file to evaluate
- **Data tab**: Chose the image orientation in a way that the spectrum runs from top left to bottom right in the extraction panel and that higher orders are at the bottom right. Select the appropriate setup.
- **Extraction tab**: Select the Rayleigh and Brillouin peaks so that the spectrum runs through the peaks.
- **Calibration tab**: Select the Rayleigh and Brillouin peaks (either automatically or manually) and run the calibration. Do that for every calibration acquired.
- **Peak Selection tab**: Select the Rayleigh and Brillouin peaks to be evaluated.
- **Evaluation**: Evaluate the measurement by clicking on "Evaluate".
- Save the evaluated measurement.