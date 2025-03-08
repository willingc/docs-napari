(high-level-diagram)=

# High level diagram

The diagram below shows a logical view of the napari architecture.
It should be viewed as a high-level overview of the main components and their relationships.

```mermaid
graph TB
    subgraph Core
        Viewer[ViewerModel]
        LayerList[LayerList]
        Camera[Camera]
        Dims[Dims]
        Grid[GridCanvas]
    end

    subgraph Events
        EventEmitter[EventEmitter]
        EmitterGroup[EmitterGroup]
        Event[Event]
    end

    subgraph Layers
        Layer[Layer Base]
        Image[Image Layer]
        Points[Points Layer]
        Labels[Labels Layer]
        Shapes[Shapes Layer]
        Surface[Surface Layer]
        Vectors[Vectors Layer]
    end

    subgraph Rendering
        VispyCanvas[VispyCanvas]
        SceneCanvas[SceneCanvas]
        VispyLayer[VispyBaseLayer]
        VispyOverlay[VispyBaseOverlay]
    end

    subgraph UI
        QtViewer[QtViewer]
        QtWindow[QtMainWindow]
        QtLayerControls[QtLayerControls]
        QtLayerList[QtLayerList]
    end

    %% Core relationships
    Viewer --> LayerList
    Viewer --> Camera
    Viewer --> Dims
    Viewer --> Grid

    %% Layer relationships
    LayerList --> Layer
    Layer --> Image
    Layer --> Points
    Layer --> Labels
    Layer --> Shapes
    Layer --> Surface
    Layer --> Vectors

    %% Event system
    Layer --> EventEmitter
    Viewer --> EmitterGroup
    EventEmitter --> Event
    EmitterGroup --> EventEmitter

    %% Rendering pipeline
    QtViewer --> VispyCanvas
    VispyCanvas --> SceneCanvas
    VispyCanvas --> VispyLayer
    VispyCanvas --> VispyOverlay
    VispyLayer --> Layer

    %% UI relationships
    QtWindow --> QtViewer
    QtViewer --> Viewer
    QtViewer --> QtLayerControls
    QtViewer --> QtLayerList
```
