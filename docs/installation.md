# Installation

stlextractor is a plain MATLAB package: there is nothing to compile or
install besides putting its folder on the MATLAB path.

## 1. Get the code

Clone the repository (or download and unzip a
[release](https://github.com/cmt-dtu-energy/stlextractor/releases)):

```shell
git clone https://github.com/cmt-dtu-energy/stlextractor.git
```

## 2. Add it to the MATLAB path

--8<-- "README.md:install"

## 3. Check the installation

```matlab
ver("STLExtractor")   % prints the installed version
which STLExtractor    % should point inside the folder you cloned
```

## Requirements

- MATLAB R2024a or newer.
- Tested on Windows, macOS and Linux.

## Running the tests

From the package folder:

```matlab
runtests("tests")
```
