package main

import (
	"encoding/json"
	"fmt"
	"github/maxiputz/gtfsCleanup/obj"
	"os"
	"strings"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: program <report.json>")
		return
	}

	filePath := os.Args[1]
	jsonData, err := os.ReadFile(filePath)
	if err != nil {
		fmt.Printf("Error reading file %s: %v\n", filePath, err)
		panic(err)
	}

	var report obj.Report
	if err := json.Unmarshal(jsonData, &report); err != nil {
		fmt.Printf("Error unmarshaling JSON: %v\n", err)
		return
	}

	n := report.Notices

	decreasing_or_equal_stop_time_distance := n[0]
	missing_trip_edge := n[7]

	fmt.Printf("decreasing_or_equal_stop_time_distance: %v\n", decreasing_or_equal_stop_time_distance.Code)
	fmt.Printf("decreasing_or_equal_stop_time_distance: %v\n", len(decreasing_or_equal_stop_time_distance.SampleNotices))

	for _, ele := range decreasing_or_equal_stop_time_distance.SampleNotices {
		if strings.Contains(ele.TripID, "74A") {
			fmt.Printf("ele.TripID: %v\n", ele.TripID)
		}
	}
	for i, ele := range n {
		fmt.Printf("i: %v\n", i)
		fmt.Printf("ele: %v\n", ele.Code)
	}

	for _, ele := range missing_trip_edge.SampleNotices {
		if strings.Contains(ele.TripID, "74A") {
			fmt.Println(fmt.Sprintf(`{"op":"remove","match":{"file":"trips.txt","trip_id":"%s"}}`, ele.TripID))

		}
	}
}
