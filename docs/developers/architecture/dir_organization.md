(napari-directory-organization)=

# napari directory organization

The majority of the napari code lives in
[`napari/`](https://github.com/napari/napari/tree/main/napari). The main
folders are:

```
napari/
├── _app_model/
├── _qt/
├── _tests/
├── _vendor/
├── _vispy/
├── benchmarks/
├── components/
├── errors/
├── layers/
├── plugins/
├── qt/
├── resources/
├── settings/
└── utils/
```

## Folders in the root directory

| Folder | Description |
| ------ | ----------- |
| [`examples/`](https://github.com/napari/napari/tree/main/examples) | contains the source [examples gallery](gallery) files. The code in these files are executed and outputs captured when building the gallery.See [](contributing-docs) for details on napari` documentation. |
| [`.github/`](https://github.com/napari/napari/tree/main/.github) | Contains our [GitHub Actions](https://docs.github.com/en/actions) [continuous integration (CI)](https://en.wikipedia.org/wiki/Continuous_integration) workflows. The majority of our CI workflows are run using GitHub Actions.

## Folders in the napari directory

| Folder | Description |
| ------ | ----------- |
| `_app_model/` | The code here relates to [app-model](app-model) and defines menu item `Actions`, providers and processors and context keys. Any Qt parts live in `napari/_qt/_qapp_model`. |
| `_qt/` | Here we define all the visual elements of napari including layer controls, menus, vispy canvas and dialogs. Any code that directly imports GUI also lives here. |
| `_vendor/` | Code vendored from other projects. This may have been because we only wanted to use a small part of a library and did not want to add another dependency. We may also have wanted to use changes in an upstream package before it has been released. |
| `_vispy/` | Code here defines how layers and their metadata are displayed on the canvas (the canvas is a vispy object onto which you can draw 'visuals'). |
| `benchmarks/` | Benchmarking code, mostly for checking the performance of layers. It is is executed in CI and is run every Sunday. See [`.github/workflows/benchmarks.yml`](https://github.com/napari/napari/blob/main/.github/workflows/benchmarks.yml) for CI workflow details. The benchmarks can also be run locally. |
| `components/` | Code that defines all components of the napari viewer, including the layerlist, dimensions and camera. |
| `errors/` | Custom napari errors (that inherit from built-in errors) are defined here. Currently we only have reader related custom errors. |
| `layers/` | Defines the classes, utilities, keybinding and mouse binding for each [layer type](using-layers). |
| `plugins/` | The code here deals with registering, activating and deactivating plugins. It also handles ingesting plugin contributions to achieve the desired effect in viewer (e.g., widget contributions should add a widget to the napari viewer). Code that defines the specification for each plugin contribution, the plugin manifest and defines plugin manager (a class that manages the currently installed plugins and their contribitions) lives in its own repo: [`npe2`](https://github.com/napari/npe2). |
| `qt/` | Public utilities that directly rely on Qt, such as the progress bar and the [thread worker](multithreading-in-napari). |
| `resources/` | Stores icons for buttons in the viewer. |
| `settings/` | Code that defines and manages napari user settings. |
| `utils/` | Commonly used classes and functions imported in variety of places. |

## General notes

* Folders beginning with `_` represent private code, that is not part of the public
  API.
  * Similarly, files beginning with `_` within folders are not considered part
    of the public API.
* Information on organization of test files can be found in [](test-organization).
  * All of `napari` tests are located in folders named `_tests`.
  * Unit tests are located in the individual folders with the modules or functions they are
testing.
  * Our integration and functional tests are located in
    the [`napari/_tests`](https://github.com/napari/napari/tree/main/napari/_tests)
    folder.

## Qt separation and modularity

[Qt](https://doc.qt.io/) is a C++ framework to build graphical user interfaces (GUIs)
that is available in Python from a number of libraries, such as
[PyQt5](https://www.riverbankcomputing.com/static/Docs/PyQt5/).
Napari uses Qt to build its GUI, but we want to remain flexible to offer other GUI
frameworks (such as a web-based GUI) in the future. Therefore,
we try to confine code that directly imports Qt (currently the only supported GUI
backend) to the folders `_qt/` and `_vispy/`.

Sometimes this means that
code needs to be split in order to place the Qt part inside `_qt/`. For example,
some of the `Action` menu items in the **View** menu require Qt. These live in
`napari/_qt/_qapp_model/qactions/_view.py` while the `Action` menu items that
do not require Qt live in `napari/_app_model/actions/_view_actions.py`.
Notice how the folder structure inside `_qt/` tries to mirror the structure of
`napari/`, with 'q' being added to the start of folders and files (e.g., `_app_model`
is named `_qapp_model` inside `_qt/`).