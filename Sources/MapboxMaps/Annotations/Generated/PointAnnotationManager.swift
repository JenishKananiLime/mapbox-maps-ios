// swiftlint:disable all
// This file is generated.
import Foundation
@_implementationOnly import MapboxCommon_Private

/// An instance of `PointAnnotationManager` is responsible for a collection of `PointAnnotation`s.
public class PointAnnotationManager: AnnotationManager {

    // MARK: - Annotations -

    /// The collection of PointAnnotations being managed
    public var annotations = [PointAnnotation]() {
        didSet {
            needsSyncAnnotations = true
        }
    }

    private var needsSyncAnnotations = false

    // MARK: - AnnotationManager protocol conformance -

    public let sourceId: String

    public let layerId: String

    public let id: String

    // MARK:- Setup / Lifecycle -

    /// Dependency required to add sources/layers to the map
    private let style: Style

    /// Dependency Required to query for rendered features on tap
    private let mapFeatureQueryable: MapFeatureQueryable

    /// Dependency required to add gesture recognizer to the MapView
    private weak var view: UIView?

    /// Indicates whether the style layer exists after style changes. Default value is `true`.
    internal let shouldPersist: Bool

    private let displayLinkParticipant = DelegatingDisplayLinkParticipant()

    internal init(id: String,
                  style: Style,
                  view: UIView,
                  mapFeatureQueryable: MapFeatureQueryable,
                  shouldPersist: Bool,
                  layerPosition: LayerPosition?,
                  displayLinkCoordinator: DisplayLinkCoordinator) {
        self.id = id
        self.style = style
        self.sourceId = id + "-source"
        self.layerId = id + "-layer"
        self.view = view
        self.mapFeatureQueryable = mapFeatureQueryable
        self.shouldPersist = shouldPersist

        do {
            try makeSourceAndLayer(layerPosition: layerPosition)
        } catch {
            Log.error(forMessage: "Failed to create source / layer in PointAnnotationManager", category: "Annotations")
        }

        self.displayLinkParticipant.delegate = self

        displayLinkCoordinator.add(displayLinkParticipant)
    }

    deinit {
        removeBackingSourceAndLayer()
    }

    func removeBackingSourceAndLayer() {
        do {
            try style.removeLayer(withId: layerId)
            try style.removeSource(withId: sourceId)
        } catch {
            Log.warning(forMessage: "Failed to remove source / layer from map for annotations due to error: \(error)",
                        category: "Annotations")
        }
    }

    internal func makeSourceAndLayer(layerPosition: LayerPosition?) throws {

        // Add the source with empty `data` property
        var source = GeoJSONSource()
        source.data = .empty
        try style.addSource(source, id: sourceId)

        // Add the correct backing layer for this annotation type
        var layer = SymbolLayer(id: layerId)
        layer.source = sourceId

        // Show all icons and texts by default in point annotations.
        layer.iconAllowOverlap = .constant(true)
        layer.textAllowOverlap = .constant(true)
        layer.iconIgnorePlacement = .constant(true)
        layer.textIgnorePlacement = .constant(true)
        if shouldPersist {
            try style._addPersistentLayer(layer, layerPosition: layerPosition)
        } else {
            try style.addLayer(layer, layerPosition: layerPosition)
        }
    }

    // MARK: - Sync annotations to map -

    /// Synchronizes the backing source and layer with the current set of annotations.
    /// This method is called automatically with each display link, but it may also be
    /// called manually in situations where the backing source and layer need to be
    /// updated earlier.
    public func syncAnnotationsIfNeeded() {
        guard needsSyncAnnotations else {
            return
        }
        needsSyncAnnotations = false

        addImageToStyleIfNeeded(style: style)

        let allDataDrivenPropertiesUsed = Set(annotations.flatMap { $0.styles.keys })
        for property in allDataDrivenPropertiesUsed {
            do {
                try style.setLayerProperty(for: layerId, property: property, value: ["get", property, ["get", "styles"]] )
            } catch {
                Log.error(forMessage: "Could not set layer property \(property) in PointAnnotationManager",
                            category: "Annotations")
            }
        }

        let featureCollection = Turf.FeatureCollection(features: annotations.map(\.feature))
        do {
            let data = try JSONEncoder().encode(featureCollection)
            guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                Log.error(forMessage: "Could not convert annotation features to json object in PointAnnotationManager",
                            category: "Annotations")
                return
            }
            try style.setSourceProperty(for: sourceId, property: "data", value: jsonObject )
        } catch {
            Log.error(forMessage: "Could not update annotations in PointAnnotationManager due to error: \(error)",
                        category: "Annotations")
        }
    }

    // MARK: - Common layer properties -

    /// If true, the icon will be visible even if it collides with other previously drawn symbols.
    public var iconAllowOverlap: Bool? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "icon-allow-overlap", value: iconAllowOverlap as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.iconAllowOverlap due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// If true, other symbols can be visible even if they collide with the icon.
    public var iconIgnorePlacement: Bool? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "icon-ignore-placement", value: iconIgnorePlacement as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.iconIgnorePlacement due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// If true, the icon may be flipped to prevent it from being rendered upside-down.
    public var iconKeepUpright: Bool? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "icon-keep-upright", value: iconKeepUpright as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.iconKeepUpright due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// If true, text will display without their corresponding icons when the icon collides with other symbols and the text does not.
    public var iconOptional: Bool? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "icon-optional", value: iconOptional as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.iconOptional due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// Size of the additional area around the icon bounding box used for detecting symbol collisions.
    public var iconPadding: Double? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "icon-padding", value: iconPadding as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.iconPadding due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// Orientation of icon when map is pitched.
    public var iconPitchAlignment: IconPitchAlignment? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "icon-pitch-alignment", value: iconPitchAlignment?.rawValue as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.iconPitchAlignment due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// In combination with `symbol-placement`, determines the rotation behavior of icons.
    public var iconRotationAlignment: IconRotationAlignment? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "icon-rotation-alignment", value: iconRotationAlignment?.rawValue as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.iconRotationAlignment due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// Scales the icon to fit around the associated text.
    public var iconTextFit: IconTextFit? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "icon-text-fit", value: iconTextFit?.rawValue as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.iconTextFit due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// Size of the additional area added to dimensions determined by `icon-text-fit`, in clockwise order: top, right, bottom, left.
    public var iconTextFitPadding: [Double]? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "icon-text-fit-padding", value: iconTextFitPadding as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.iconTextFitPadding due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// If true, the symbols will not cross tile edges to avoid mutual collisions. Recommended in layers that don't have enough padding in the vector tile to prevent collisions, or if it is a point symbol layer placed after a line symbol layer. When using a client that supports global collision detection, like Mapbox GL JS version 0.42.0 or greater, enabling this property is not needed to prevent clipped labels at tile boundaries.
    public var symbolAvoidEdges: Bool? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "symbol-avoid-edges", value: symbolAvoidEdges as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.symbolAvoidEdges due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// Label placement relative to its geometry.
    public var symbolPlacement: SymbolPlacement? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "symbol-placement", value: symbolPlacement?.rawValue as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.symbolPlacement due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// Distance between two symbol anchors.
    public var symbolSpacing: Double? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "symbol-spacing", value: symbolSpacing as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.symbolSpacing due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// Determines whether overlapping symbols in the same layer are rendered in the order that they appear in the data source or by their y-position relative to the viewport. To control the order and prioritization of symbols otherwise, use `symbol-sort-key`.
    public var symbolZOrder: SymbolZOrder? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "symbol-z-order", value: symbolZOrder?.rawValue as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.symbolZOrder due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// If true, the text will be visible even if it collides with other previously drawn symbols.
    public var textAllowOverlap: Bool? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "text-allow-overlap", value: textAllowOverlap as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.textAllowOverlap due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// If true, other symbols can be visible even if they collide with the text.
    public var textIgnorePlacement: Bool? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "text-ignore-placement", value: textIgnorePlacement as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.textIgnorePlacement due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// If true, the text may be flipped vertically to prevent it from being rendered upside-down.
    public var textKeepUpright: Bool? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "text-keep-upright", value: textKeepUpright as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.textKeepUpright due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// Text leading value for multi-line text.
    public var textLineHeight: Double? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "text-line-height", value: textLineHeight as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.textLineHeight due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// Maximum angle change between adjacent characters.
    public var textMaxAngle: Double? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "text-max-angle", value: textMaxAngle as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.textMaxAngle due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// If true, icons will display without their corresponding text when the text collides with other symbols and the icon does not.
    public var textOptional: Bool? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "text-optional", value: textOptional as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.textOptional due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// Size of the additional area around the text bounding box used for detecting symbol collisions.
    public var textPadding: Double? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "text-padding", value: textPadding as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.textPadding due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// Orientation of text when map is pitched.
    public var textPitchAlignment: TextPitchAlignment? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "text-pitch-alignment", value: textPitchAlignment?.rawValue as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.textPitchAlignment due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// In combination with `symbol-placement`, determines the rotation behavior of the individual glyphs forming the text.
    public var textRotationAlignment: TextRotationAlignment? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "text-rotation-alignment", value: textRotationAlignment?.rawValue as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.textRotationAlignment due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// To increase the chance of placing high-priority labels on the map, you can provide an array of `text-anchor` locations: the renderer will attempt to place the label at each location, in order, before moving onto the next label. Use `text-justify: auto` to choose justification based on anchor position. To apply an offset, use the `text-radial-offset` or the two-dimensional `text-offset`.
    public var textVariableAnchor: [String]? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "text-variable-anchor", value: textVariableAnchor as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.textVariableAnchor due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// The property allows control over a symbol's orientation. Note that the property values act as a hint, so that a symbol whose language doesn’t support the provided orientation will be laid out in its natural orientation. Example: English point symbol will be rendered horizontally even if array value contains single 'vertical' enum value. The order of elements in an array define priority order for the placement of an orientation variant.
    public var textWritingMode: [String]? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "text-writing-mode", value: textWritingMode as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.textWritingMode due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// Distance that the icon's anchor is moved from its original placement. Positive values indicate right and down, while negative values indicate left and up.
    public var iconTranslate: [Double]? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "icon-translate", value: iconTranslate as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.iconTranslate due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// Controls the frame of reference for `icon-translate`.
    public var iconTranslateAnchor: IconTranslateAnchor? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "icon-translate-anchor", value: iconTranslateAnchor?.rawValue as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.iconTranslateAnchor due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// Distance that the text's anchor is moved from its original placement. Positive values indicate right and down, while negative values indicate left and up.
    public var textTranslate: [Double]? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "text-translate", value: textTranslate as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.textTranslate due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// Controls the frame of reference for `text-translate`.
    public var textTranslateAnchor: TextTranslateAnchor? {
        didSet {
            do {
                try style.setLayerProperty(for: layerId, property: "text-translate-anchor", value: textTranslateAnchor?.rawValue as Any)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.textTranslateAnchor due to error: \(error)",
                            category: "Annotations")
            }
        }
    }

    /// Font stack to use for displaying text.
    public var textFont: [String]? {
        didSet {
            do {
                guard let textFont = textFont else { return }
                try style.setLayerProperty(for: layerId, property: "text-font", value: textFont)
            } catch {
                Log.warning(forMessage: "Could not set PointAnnotationManager.textFont",
                            category: "Annotations")
            }
        }
    }

    // MARK: - Selection Handling -

    /// Set this delegate in order to be called back if a tap occurs on an annotation being managed by this manager.
    public weak var delegate: AnnotationInteractionDelegate? {
        didSet {
            if delegate != nil {
                setupTapRecognizer()
            } else {
                guard let view = view, let recognizer = tapGestureRecognizer else { return }
                view.removeGestureRecognizer(recognizer)
                tapGestureRecognizer = nil
            }
        }
    }

    /// The `UITapGestureRecognizer` that's listening to touch events on the map for the annotations present in this manager
    public var tapGestureRecognizer: UITapGestureRecognizer?

    internal func setupTapRecognizer() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        view?.addGestureRecognizer(tapRecognizer)
        tapGestureRecognizer = tapRecognizer
    }

    @objc internal func handleTap(_ tap: UITapGestureRecognizer) {
        let options = RenderedQueryOptions(layerIds: [layerId], filter: nil)
        mapFeatureQueryable.queryRenderedFeatures(
            at: tap.location(in: view),
            options: options) { [weak self] (result) in

            guard let self = self else { return }

            switch result {

            case .success(let queriedFeatures):
                if let annotationIds = queriedFeatures.compactMap({ $0.feature?.properties?["annotation-id"] }) as? [String] {

                    let tappedAnnotations = self.annotations.filter { annotationIds.contains($0.id) }
                    self.delegate?.annotationManager(
                        self,
                        didDetectTappedAnnotations: tappedAnnotations)
                }

            case .failure(let error):
                Log.warning(forMessage: "Failed to query map for annotations due to error: \(error)",
                            category: "Annotations")
            }
        }
    }
}

extension PointAnnotationManager: DelegatingDisplayLinkParticipantDelegate {
    func participate(for participant: DelegatingDisplayLinkParticipant) {
        syncAnnotationsIfNeeded()
    }
}

// End of generated file.
// swiftlint:enable all
