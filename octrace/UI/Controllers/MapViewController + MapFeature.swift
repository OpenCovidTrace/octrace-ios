extension MapViewController {

    struct MapFeatureValue: Codable {
        let features: [MapFeature]
    }

    struct MapFeature: Codable {
        let attributes: MapAttribute
    }

    struct MapAttribute: Codable {
        let ADM0_NAME: String
        let CENTER_LAT: Double?
        let CENTER_LON: Double?
        let cum_conf: Int
        let cum_death: Int
    }

}
