import UIKit
import MapboxMaps

@objc(CustomStyleURLExample)
internal class CustomStyleURLExample: UIViewController, ExampleProtocol {

    internal var mapView: MapView!

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Create a URL for a custom style created in Mapbox Studio.
        guard let customStyleURL = URL(string: "mapbox://styles/examples/cke97f49z5rlg19l310b7uu7j") else {
            fatalError("Style URL is invalid")
        }

        let options = MapInitOptions(styleURI: .custom(url: customStyleURL))
        mapView = MapView(frame: view.bounds, mapInitOptions: options)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)

        mapView.mapboxMap.onNext(.styleLoaded) { [weak self] _ in
            // The below line is used for internal testing purposes only.
            self?.finish()
        }
    }
}
