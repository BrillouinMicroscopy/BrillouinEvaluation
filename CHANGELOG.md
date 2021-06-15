## 1.5.2 - 2021-06-15

### Fixed
- Fix spectrum extraction for time points outside calibrations #35
- Also extrapolate to earlier time points for frequency calculation #36
- Don't hide singleton dimensions when exporting for Python #37

## 1.5.1 - 2021-02-19

### Fixed
- Minor layout fixes #34
- Don't break auto-evaluation if data field is absent d0a0239

## 1.5.0 - 2021-02-08

### Added
- Allow masking for all 2D data #24
- Adjust colormaps used #10
- Allow to show the time in evaluation view #22
- Read exposure time from acquisition file #17 #29
- Store evaluation files in HDF5 format #19 #27 
- Implement exporting data for Python #26 #28
- Update program screenshots #30
- Add license
- Add readme
- Add example data file

### Fixed
- Fix failing constraints fit when frequency axis contains NaNs #21
- Adjust exportValuesAll script for Mac
- Fix title bar version string
- Code cleanup #25

## 1.4.3 - 2020-10-29

### Added
- Add changelog

### Fixed
- Gracefully handle non-unique timestamps #16