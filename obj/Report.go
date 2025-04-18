package obj

type Report struct {
	Notices []NoticesStruct `json:"notices"`
}

type NoticesStruct struct {
	Code          string                `json:"code"`
	Severity      string                `json"severity"`
	SampleNotices []SampleNoticesStruct `json:"sampleNotices"`
}

type SampleNoticesStruct struct {
	TripID                string  `json:"tripId"`
	StopID                string  `json:"stopId"`
	CSVRowNumber          int     `json:"csvRowNumber"`
	ShapeDistTraveled     float64 `json:"shapeDistTraveled"`
	StopSequence          int     `json:"stopSequence"`
	PrevCSVRowNumber      int     `json:"prevCsvRowNumber"`
	PrevShapeDistTraveled float64 `json:"prevShapeDistTraveled"`
	PrevStopSequence      int     `json:"prevStopSequence"`
}
