package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"github/maxiputz/gtfsCleanup/obj"
	"os"
	"reflect"
	"strconv"
	"strings"
	"unicode"

	"github.com/olekukonko/tablewriter"
)

// Config represents the structure of the config.json file
type Config struct {
	Code        string          `json:"code"`
	SNProp      string          `json:"SNProp"`
	SNValFilter string          `json:"SNValFilter"`
	Template    json.RawMessage `json:"template"`
	InFile      string          `json:"inFile"`
	OutFile     string          `json:"outFile"`
}

func main() {
	// Define command‑line flags
	configPath := flag.String("c", "config.json", "path to config file")
	inspectFile := flag.String("i", "", "path to report file to list all notice codes")
	flag.Parse()

	// If -i is set, enter inspect mode: print all notice codes
	if *inspectFile != "" {
		reportData, err := os.ReadFile(*inspectFile)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error reading report file %s: %v\n", *inspectFile, err)
			os.Exit(1)
		}
		var report obj.Report
		if err := json.Unmarshal(reportData, &report); err != nil {
			fmt.Fprintf(os.Stderr, "Error parsing JSON: %v\n", err)
			os.Exit(1)
		}

		table := tablewriter.NewWriter(os.Stdout)

		table.SetHeader([]string{"Severity", "Entries", "Code"})

		for _, notice := range report.Notices {
			table.Append([]string{
				notice.Severity,
				strconv.Itoa(len(notice.SampleNotices)),
				notice.Code,
			})
		}

		table.Render() // prints the table
		return
	}

	// Otherwise, load configuration
	cfgData, err := os.ReadFile(*configPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading config file %s: %v\n", *configPath, err)
		os.Exit(1)
	}
	var cfg Config
	if err := json.Unmarshal(cfgData, &cfg); err != nil {
		fmt.Fprintf(os.Stderr, "Error parsing config JSON: %v\n", err)
		os.Exit(1)
	}

	// Read the GTFS report
	reportData, err := os.ReadFile(cfg.InFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading report file %s: %v\n", cfg.InFile, err)
		os.Exit(1)
	}
	var report obj.Report
	if err := json.Unmarshal(reportData, &report); err != nil {
		fmt.Fprintf(os.Stderr, "Error parsing report JSON: %v\n", err)
		os.Exit(1)
	}

	// Find the index of the notice matching the configured code
	codeIndex := -1
	for i, notice := range report.Notices {
		if notice.Code == cfg.Code {
			codeIndex = i
			break
		}
	}
	if codeIndex == -1 {
		// No matching notices: nothing to do
		os.Exit(0)
	}
	selected := report.Notices[codeIndex]

	// Prepare template string
	tmpl := string(cfg.Template)

	// Helper: convert JSON property name to Go struct field name
	toField := func(jsonProp string) string {
		r := []rune(jsonProp)
		if len(r) == 0 {
			return ""
		}
		// Uppercase first letter
		s := string(unicode.ToUpper(r[0])) + string(r[1:])
		// If ends with "Id", normalize to "ID"
		if strings.HasSuffix(s, "Id") {
			s = strings.TrimSuffix(s, "Id") + "ID"
		}
		return s
	}

	fieldName := toField(cfg.SNProp)

	// Build modifications
	outLines := []string{}
	for _, sample := range selected.SampleNotices {
		v := reflect.ValueOf(sample)
		f := v.FieldByName(fieldName)
		if !f.IsValid() {
			continue
		}
		val := f.String()
		if strings.Contains(val, cfg.SNValFilter) {
			// Fill in the template
			entry := fmt.Sprintf(tmpl, val)
			fmt.Println(entry)
			outLines = append(outLines, entry)
		}
	}

	// Write output to configured file
	if err := os.WriteFile(cfg.OutFile, []byte(strings.Join(outLines, "\n")), 0664); err != nil {
		fmt.Fprintf(os.Stderr, "Error writing output file %s: %v\n", cfg.OutFile, err)
		os.Exit(1)
	}
}
