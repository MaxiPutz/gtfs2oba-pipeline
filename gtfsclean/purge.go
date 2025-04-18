package gtfsclean

import (
	"bufio"
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"sort"
	"strconv"
)

// PurgeDecreasing rewrites stop_times.txt in gtfsDir, dropping non-increasing shape_dist_traveled.
func PurgeDecreasing(gtfsDir string) error {
	inPath := fmt.Sprintf("%s/stop_times.txt", gtfsDir)
	outPath := fmt.Sprintf("%s/stop_times.cleaned.txt", gtfsDir)

	// open input
	inf, err := os.Open(inPath)
	if err != nil {
		return err
	}
	defer inf.Close()
	reader := csv.NewReader(bufio.NewReader(inf))
	reader.FieldsPerRecord = -1

	// read header
	header, err := reader.Read()
	if err != nil {
		return err
	}

	// locate columns
	var idxTrip, idxSeq, idxShape int = -1, -1, -1
	for i, h := range header {
		switch h {
		case "trip_id":
			idxTrip = i
		case "stop_sequence":
			idxSeq = i
		case "shape_dist_traveled":
			idxShape = i
		}
	}
	if idxTrip < 0 || idxSeq < 0 || idxShape < 0 {
		return fmt.Errorf("missing required columns")
	}

	// group records by trip_id
	type rec struct {
		row       []string
		seq       int
		shapeDist float64
	}
	trips := make(map[string][]rec)
	for {
		row, err := reader.Read()
		if err == io.EOF {
			break
		} else if err != nil {
			return err
		}
		seq, _ := strconv.Atoi(row[idxSeq])
		dist, _ := strconv.ParseFloat(row[idxShape], 64)
		trips[row[idxTrip]] = append(trips[row[idxTrip]], rec{row, seq, dist})
	}

	// open output
	outf, err := os.Create(outPath)
	if err != nil {
		return err
	}
	defer outf.Close()
	writer := csv.NewWriter(outf)
	defer writer.Flush()
	writer.Write(header)

	// process each trip
	for _, records := range trips {
		sort.Slice(records, func(i, j int) bool {
			return records[i].seq < records[j].seq
		})
		var prev float64 = -1
		for _, r := range records {
			if r.shapeDist > prev {
				writer.Write(r.row)
				prev = r.shapeDist
			}
			// else drop
		}
	}

	// replace original file if you like:
	// os.Rename(outPath, inPath)
	return nil
}
