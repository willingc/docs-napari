(best-practices)=
# Best practices for plugin developers

There are a number of good and bad practices that may not be immediately obvious
when developing a plugin.  This page covers some known practices that could
affect the ability to install or use your plugin effectively.


(best-practices-no-qt-backend)=
## Don't include `napari[all]`, `PySide2`, `PyQt5` or `PyQt6` in your plugin's default dependencies.

*This is important! Avoid including any form of Qt in your plugin's dependencies!*

Napari supports *both* PyQt and PySide backends for Qt.  It is up to the
end-user to choose which one they want. If they installed napari with `pip
install napari[all]`, then this includes `PyQt5` from PyPI as the default backend.
If they installed via `conda install napari pyqt`, then they'll have `PyQt5`,
but from conda-forge instead of PyPI. Meanwhile, the napari bundle installs with PySide2.
Users are also free to install PyQt6, which is fully supported, or the 
experimental PySide6 backend.

Here's what can go wrong if you *also* declare one of these backends **or napari[all]**
in the `dependencies`/`install_requires` section of your plugin metadata:

- If they installed via `conda install napari pyqt` and then they install your plugin
  via `pip` (or vice versa) then there *will* be a binary incompatibility between the 
  conda `pyqt` installation, and the `PyQt5` installation from PyPI. *This will very likely
  lead to a broken environment, forcing the user to re-create their entire
  environment and re-install napari*. This is an unfortunate consequence of
  [package naming decisions](https://github.com/ContinuumIO/anaconda-issues/issues/1554),
  and it's not something napari can fix.
- Alternatively, they may end up with some combination of *both* PyQt5, PyQt6, PySide2,
  and PySide6 in their environment: the Qt backend they had installed and the one your
  plugin installed as a dependency. This is will not *always* to break things, but
  it will lead to unexpected and difficult to debug problems. 
- Both of the above cases are most likely to happen with the built-in GUI napari plugin manager,
  which will install your plugin plus the base dependencies. As a result, this frequently 
  occurs with the bundle app. Trying to fix these issues is almost impossible for GUI centric
  users, leaving them the only recourse of re-installing.

````{tip}
1. You can still include a specific Qt backend in optional `dev` or `testing` dependencies!
Just *don't* include a specific Qt backend (or `napari[all]`, which currently includes PyQt5)
in your base dependencies.
2. You can include an optional `all` dependency on `napari[all]` to mimic the simple,
command line installation in a fresh environment. In `pyproject.toml` this would be:

    ```
    [project.optional-dependencies]
    all = [napari["all]"]
    ```

    And then your plugin could be installed with napari and the default Qt backend using:
    ```bash
    pip install my_plugin[all]
    ```
    Meanwhile, the napari plugin manager will still just install your plugin without the Qt
    dependency.  

````

## Don't import from any specific Qt backend (e.g. PyQt5, PySide2, etc.) in your plugin: use `qtpy`

    If you use `from PyQt5 import QtCore` (or similar) in your plugin, but the
    end-user has chosen to use `PySide2` for their Qt backend — or vice versa —
    then your plugin will fail to import.  Instead use `from qtpy import
    QtCore`.  `qtpy` is a [Qt compatibility layer](https://github.com/spyder-ide/qtpy)
    that will import from whatever backend is installed in the environment.


## Try not to depend on packages that require C compilation if these packages do not offer wheels

````{tip}
This requires some awareness of how your dependencies are built and distributed...

Some python packages write a portion of their code in lower level languages like
C or C++ and compile that code into "C Extensions" that can be called by python
at runtime.  This can *greatly* improve performance, but it means that the
package must be compiled for *each* platform (i.e. Windows, Mac, Linux) that the
package wants to support.  Some packages do this compilation step ahead of time,
by distributing "[wheels](https://realpython.com/python-wheels/)" on
[PyPI](https://pypi.org/)... or by providing pre-compiled packages via `conda`.
Other packages simply distribute the source code (as an "sdist") and expect the
end-user to compile it on their own computer.  Compiling C code requires
software that is not always installed on every computer. (If you've ever tried
to `python -m pip install` a package and had it fail with a big wall of red text saying
something about `gcc`, then you've run into a package that doesn't distribute
wheels, and you didn't have the software required to compile it).
````


As a plugin developer, if you depend on a package that uses C extensions but
doesn't distribute a pre-compiled wheel, then it's very likely that your users
will run into difficulties installing your plugin:

- *What is a "wheel"?*

  Briefly, a wheel is a *built distribution*, containing code that is
  pre-compiled for a specific operating system.

  For more detail, see [What Are Python Wheels and Why Should You
  Care?](https://realpython.com/python-wheels/)

- *How do I know if my dependency offers a wheel*

  There are many ways, but a sure-fire way to know is to go to the respective
  package on PyPI, and click on the "Download Files" link.  If the package
  offers wheels, you'll see one or more files ending in `.whl`.  For example,
  [napari offers a wheel](https://pypi.org/project/napari/#files).  If a package
  *doesn't* offer a wheel, it may still be ok if it's just a pure python package
  that doesn't have any C extensions...

- *How do I know if one of my dependencies uses C Extensions?*

  First, look for the presence of C or C++ in the "Languages" side-bar
  of the repository. Otherwise, there's no one right way, but more often than not, 
  if a package uses C extensions, then their `setup.py` file will use the
  [`ext_modules`
  argument](https://docs.python.org/3.11/distutils/setupscript.html#describing-extension-modules).
    

````{admonition} What about conda?
**conda** also distributes & installs pre-compiled packages, though they aren't
wheels.  We encourage you to make your plugins 
[available on conda-forge](deploying-to-conda-forge), which
is a great way to handle binary dependencies in a reliable way. The built-in 
[napari plugin manager](https://napari.org/napari-plugin-manager) currently
supports installing plugins from both PyPI and conda-forge, with the default matching
the source of the napari installation.
````

(best_practice_napari_type)=
## Don't require `napari` if not necessary

It's good practice to not depend on `napari` if not strictly necessary.
If you only use `napari` for type annotations, we recommend that you use strings
instead of importing the types. This is called a
[Forward reference](https://peps.python.org/pep-0484/#forward-references).
For example, you can see in the
[widget contribution guide](widgets-contribution-guide) that napari type annotations
are strings and not imported.

If you'd like to maintain IDE type support and autocompletion, you can
still do so by hiding the napari imports inside of a {attr}`typing.TYPE_CHECKING`
clause:

```python
from typing import TYPE_CHECKING

if TYPE_CHECKING:
  import napari

@magicgui
def my_func(data: 'napari.types.ImageData') -> 'napari.types.ImageData':
    ...
```

This will not require napari at runtime, but if it is installed in your
development environment, you will still get all the type inference.

## Don't leave resources open

It's always good practice to clean up resources like open file handles and
databases.  As a napari plugin it's particularly important to do this (and
especially for Windows users).  If someone tries to use the built-in plugin
manager to *uninstall* your plugin, open file handles and resources may cause
the process to fail or even leave your plugin in an "installed-but-unusable"
state.

Don't do this:

```py
# my_plugin/module.py
import json

data_file = open("some_data_in_my_plugin.json")
data = json.load(data_file)
```

Instead, make sure to close your resource after grabbing the data (ideally by
using a context manager, but manually otherwise):

```py
with open("some_data_in_my_plugin.json") as data_file:
    data = json.load(data_file)
```

## Write extensive tests for your plugin!

Programmer and author Bruce Eckel famously wrote:

> "If it's not tested, it's broken"

It's true.  High test coverage is one way to show your users that you are
dedicated to the stability of your plugin. Aim for 100%!

Of course, simply having 100% coverage doesn't mean your code is bug-free, so
make sure that you test all of the various ways that your code might be called.

See [Tips for testing napari plugins](plugin-testing-tips).

(best-practices-test-coverage)=

### How to check test coverage?

The [napari plugin
template](https://github.com/napari/napari-plugin-template) is already set
up to report test coverage, but you can test locally as well, using
[pytest-cov](https://github.com/pytest-dev/pytest-cov)

1. `python -m pip install pytest-cov`
2. Run your tests with `pytest --cov=<your_package> --cov-report=html`
3. Open the resulting report in your browser: `open htmlcov/index.html`
4. The report will show line-by-line what is being tested, and what is being
   missed. Continue writing tests until everything is covered! If you have
   lines that you *know* never need to be tested (like debugging code) you can
   [exempt specific
   lines](https://coverage.readthedocs.io/en/6.4.4/excluding.html#excluding-code-from-coverage-py)
   from coverage with the comment `# pragma: no cover`
5. In the napari plugin template, coverage tests from github actions will be uploaded to codecov.io

## Set style for additional windows in your plugin

In napari plugins we strongly advise additional widgets be docked in the main napari viewer,
but sometimes a separate window is required.
The best practice is to use [`QDialog`](https://doc.qt.io/qt-5/qdialog.html)
based windows with parent set to widget
already docked in the viewer.

```python
from qtpy.QtWidgets import QDialog, QWidget, QSpinBox, QPushButton, QGridLayout, QLabel

class MyInputDialog(QDialog):
    def __init__(self, parent: QWidget):
        super().__init__(parent)
        self.setWindowTitle("My Input Dialog")
        self.number = QSpinBox()
        self.ok_btn = QPushButton("OK")
        self.cancel_btn = QPushButton("Cancel")

        layout = QGridLayout()
        layout.addWidget(QLabel("Number:"), 0, 0)
        layout.addWidget(self.number, 0, 1)
        layout.addWidget(self.ok_btn, 1, 0)
        layout.addWidget(self.cancel_btn, 1, 1)
        self.setLayout(layout)

        self.ok_btn.clicked.connect(self.accept)
        self.cancel_btn.clicked.connect(self.reject)

class MyWidget(QWidget):
    def __init__(self, viewer: "napari.Viewer"):
        super().__init__()
        self.viewer = viewer
        self.open_dialog = QPushButton("Open dialog")
        self.open_dialog.clicked.connect(self.open_dialog_clicked)

    def open_dialog_clicked(self):
        # setting parent to self allows the dialog to inherit its
        # style from the viewer by pass self as argument
        dialog = MyInputDialog(self)
        dialog.exec_()
        if dialog.result() == QDialog.Accepted:
            print(dialog.number.value())
```

If there is a particular reason that you need to use a separate window that
inherits from `QWidget`, not `QDialog`, then you could use the `get_current_stylesheet`
and {func}`get_stylesheet <napari.qt.get_stylesheet>` functions from the
{mod}`napari.qt <napari.qt>` module.

Here is a `magicgui` example (but could be easily generalised to native `qt` based widgets):

```python
from magicgui import magicgui

from napari.qt import get_current_stylesheet
from napari.settings import get_settings

def sample_add(a: int, b: int) -> int:
    return a + b

@magicgui
def sample_add(a: int, b: int) -> int:
    return a + b

def change_style():
    sample_add.native.setStyleSheet(get_current_stylesheet())


get_settings().appearance.events.theme.connect(change_style)
change_style()

```

## Do not package your tests as a top-level package

If you are using the [napari plugin template](https://github.com/napari/napari-plugin-template),
your tests are already packaged in the correct way. No further action required!

```bash
# project structure suggested by the napari plugin template
src/
  my_package/
    _tests/
      test_my_module.py
    __init__.py
    my_module.py
pyproject.toml
README.md
```

However, if your project structure is already following a different scheme,
the testing logic might live outside your package, as a top-level directory:

```bash
# alternative structure, no src/ directory, testing logic outside the package
my_package/
  __init__.py
  my_module.py
tests/
  conftest.py
  test_my_module.py
pyproject.toml
README.md
```

Under these circumstances, your build backend (usually `setuptools`) might include `tests` as a
separate package that will be installed next to `my_package`!
Most of the time, this is not wanted; e.g. do you want to do `import tests`? Probably not!
Additionally, this unwanted behavior might cause installation issues with other projects.

Ideally, you could change your project structure to follow the recommended skeleton followed in
the napari plugin template. Howevever, if that's unfeasible, you can fix this in the project metadata files.

You need to explicitly _exclude_ the top-level `tests` directory from the packaged contents:

```toml
# pyproject.toml
...
[options.packages.find]
exclude =
    tests
    tests.*
```

```python
# setup.py
...
setup(
    ...
    packages=find_packages(exclude=("tests", "tests.*")),
    ...
)
```

Note this also applies to other top-level directories, like `test`, `_tests`, `testing`, etc.

You can find more information in the
[package discovery documentation for `setuptools`](https://setuptools.pypa.io/en/latest/userguide/package_discovery.html).


## License issues when including code from 3rd parties

Plugins will often depend on 3rd party packages beyond `napari` itself.
These dependencies are usually included in the project metadata in `pyproject.toml`.
However, sometimes developers might include code from 3rd parties directly in their project.
Sometimes it will be just a little snippet, maybe slightly modified to suit the project needs.
Some other times, a whole project will be included entirely (vendoring).

This constitutes an act of source code redistribution, which is usually covered by many licensing schemes.
Most of the time, this means you need to explicitly include the vendored project license in the source.
This is the case for Apache, BSD and MIT-style licenses.
Do note that some projects might NOT allow redistribution without explicit approval.
Others will prevent it entirely... Be mindful and check the requirements before distributing your package!

```{note}
If you are vendoring other projects, please add an acknowledgement in your README.
The license details in your project metadata should also include this information!
```

## Outdated, npe1 only: Don't import heavy dependencies at the top of your module

````{note}
This point will be less relevant when we move to the second generation
[manifest-based plugin
declaration](https://github.com/napari/napari/issues/3115), but it's still a
good idea to delay importing your plugin-specific dependencies and modules until
*after* your hookspec has been called.  This helps napari stay quick and
responsive at startup.
````



Consider the following example plugin:

```ini
[options.entry_points]
napari.plugin =
  plugin-name = mypackage.napari_plugin
```

In this example, `my_heavy_dependency_like_tensorflow` will be imported
*immediately* when napari is launched, and we search the entry_point
`mypackage.napari_plugin` for decorated hook specifications.

```py
# mypackage/napari_plugin.py
from napari_plugin_engine import napari_hook_specification
from qtpy.QtWidgets import QWidget
from my_heavy_dependency_like_tensorflow import something_amazing

class MyWidget(QWidget):
    def do_something_amazing(self):
        return something_amazing()

@napari_hook_specification
def napari_experimental_provide_dock_widget():
    return MyWidget
```

This can deterioate the end-user experience, and make napari feel slugish. Best
practice is to delay heavy imports until right before they are used.  The
following slight modification will help napari load much faster:

```py
# mypackage/napari_plugin.py
from napari_plugin_engine import napari_hook_specification
from qtpy.QtWidgets import QWidget

class MyWidget(QWidget):
    def do_something_amazing(self):
        # import has been moved here, will happen only after the user
        # has opened and used this widget.
        from my_heavy_dependency_like_tensorflow import something_amazing

        return something_amazing()
```

(again, the second gen napari plugin engine will help improve this situation,
but it's still a good idea!)
