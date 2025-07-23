package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

func main() {
	var (
		url                       string
		revision                  string
		refspec                   string
		path                      string
		sslVerify                 string
		submodules                string
		depth                     string
		sparseCheckoutDirectories string
	)

	flag.StringVar(&url, "url", "", "Git repository URL")
	flag.StringVar(&revision, "revision", "HEAD", "Git revision")
	flag.StringVar(&refspec, "refspec", "", "Git refspec")
	flag.StringVar(&path, "path", ".", "Path to clone into")
	flag.StringVar(&sslVerify, "sslVerify", "true", "SSL verification")
	flag.StringVar(&submodules, "submodules", "true", "Initialize submodules")
	flag.StringVar(&depth, "depth", "1", "Clone depth")
	flag.StringVar(&sparseCheckoutDirectories, "sparseCheckoutDirectories", "", "Sparse checkout dirs")
	flag.Parse()

	// Create directory if it doesn't exist
	if err := os.MkdirAll(path, 0755); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to create directory: %v\n", err)
		os.Exit(1)
	}

	// Configure git SSL verification
	if sslVerify == "false" {
		runCommand("git", "config", "--global", "http.sslVerify", "false")
	}

	// Clone the repository
	cloneArgs := []string{"clone"}

	if depth != "0" && depth != "" {
		cloneArgs = append(cloneArgs, "--depth", depth)
	}

	if refspec != "" {
		cloneArgs = append(cloneArgs, "--no-checkout")
	}

	cloneArgs = append(cloneArgs, url, path)

	if err := runCommand("git", cloneArgs...); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to clone: %v\n", err)
		os.Exit(1)
	}

	// Change to repository directory
	if err := os.Chdir(path); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to change directory: %v\n", err)
		os.Exit(1)
	}

	// Fetch specific refspec if provided
	if refspec != "" {
		if err := runCommand("git", "fetch", "origin", refspec); err != nil {
			fmt.Fprintf(os.Stderr, "Failed to fetch refspec: %v\n", err)
			os.Exit(1)
		}
	}

	// Checkout revision
	if revision != "" && revision != "HEAD" {
		if err := runCommand("git", "checkout", revision); err != nil {
			fmt.Fprintf(os.Stderr, "Failed to checkout revision: %v\n", err)
			os.Exit(1)
		}
	}

	// Initialize submodules if requested
	if submodules == "true" {
		if err := runCommand("git", "submodule", "update", "--init", "--recursive"); err != nil {
			fmt.Fprintf(os.Stderr, "Warning: Failed to update submodules: %v\n", err)
		}
	}

	// Handle sparse checkout
	if sparseCheckoutDirectories != "" {
		runCommand("git", "config", "core.sparseCheckout", "true")
		sparseFile := ".git/info/sparse-checkout"
		dirs := strings.Split(sparseCheckoutDirectories, ",")
		content := strings.Join(dirs, "\n")
		if err := os.WriteFile(sparseFile, []byte(content), 0644); err != nil {
			fmt.Fprintf(os.Stderr, "Failed to write sparse-checkout: %v\n", err)
			os.Exit(1)
		}
		runCommand("git", "read-tree", "-m", "-u", "HEAD")
	}

	fmt.Println("Successfully cloned", url, "to", path)
}

func runCommand(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
