# Poly

```console
 ____        ___
/\  _`\     /\_ \
\ \ \L\ \___\//\ \    __  __
 \ \ ,__/ __`\\ \ \  /\ \/\ \
  \ \ \/\ \L\ \\_\ \_\ \ \_\ \
   \ \_\ \____//\____\\/`____ \
    \/_/\/___/ \/____/ `/___/> \
                          /\___/
                          \/__/

Poly will help you deploy multi-app.
```

## Usage

Poly is used as a dependency (subchart).

### Step by step to install

Create your chart, then remove boilerplates

```console
helm create mychart

# remove boilerplates, be careful the path
rm -rf mychart/templates/*
```

Add dependency in `Chart.yaml`

```yaml
...
dependencies:
  - name: poly
    repository: https://github.com/cyanwind23/poly
    version: "3.0.3" # this will use latest version, change it to the version you want
```

Update dependency

```console
helm dependency update
```

Add your app config in `values.yaml`

```yaml
...
poly:
  apps:
    <app-name>: # ex: nginx
      enabled: true
      # Your app config goes here
  ...
```

## Install without connecting to registry

Ask maintainer for `poly` package. It's a `tgz` file such as `poly-1.0.0.tgz`
Create your chart, then remove boilerplates

```console
helm create mychart

# remove boilerplates, be careful the path
rm -rf mychart/templates/*
```

Put `poly-<version>.tgz` file into `charts` directory
Add dependency in `Chart.yaml`

```yaml
...
dependencies:
  - name: poly
    repository: file://charts/poly-<version>.tgz
    version: "<version>" # ex: "1.0.0"
```

Add your app config in `values.yaml`

```yaml
...
poly:
  apps:
    <app-name>: # ex: nginx
      enabled: true
      # Your app config goes here
  ...
```

## Get Poly config format and default values

You can get app config format of Poly by running command:

```console
helm show values https://github.com/cyanwind23/poly > poly-values.yaml
```

Or this if you do not have permission to access the registry, get the values file from packed chart
> Note: Replace with your Poly version

```console
helm show values charts/poly-<version>.tgz > poly-values.yaml
```
