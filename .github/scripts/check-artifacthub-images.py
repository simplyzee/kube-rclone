"""Check the artifacthub.io/images annotation matches the images the chart deploys.

Usage: check-artifacthub-images.py <chart-dir> <values-file> [<values-file> ...]

Renders the chart once per values file and collects every container image.
The union must equal the images listed in Chart.yaml, so Artifact Hub's
security scanner always checks what users actually run.
"""
import subprocess
import sys

import yaml


def images_in(doc):
    spec = (doc or {}).get("spec", {})
    if doc and doc.get("kind") == "CronJob":
        spec = spec.get("jobTemplate", {}).get("spec", {})
    pod = spec.get("template", {}).get("spec", {})
    for key in ("initContainers", "containers"):
        for c in pod.get(key, []) or []:
            yield c["image"]


chart_dir, values_files = sys.argv[1], sys.argv[2:]
chart = yaml.safe_load(open(f"{chart_dir}/Chart.yaml"))
listed = {i["image"] for i in yaml.safe_load(chart["annotations"]["artifacthub.io/images"])}

rendered = set()
for values in values_files:
    out = subprocess.run(
        ["helm", "template", "check", chart_dir, "-f", values],
        check=True, capture_output=True, text=True,
    ).stdout
    for doc in yaml.safe_load_all(out):
        rendered.update(images_in(doc))

missing = rendered - listed
extra = listed - rendered
print("listed:  ", sorted(listed))
print("rendered:", sorted(rendered))
if missing or extra:
    if missing:
        print("Rendered but not in artifacthub.io/images:", sorted(missing))
    if extra:
        print("In artifacthub.io/images but never rendered:", sorted(extra))
    sys.exit(1)
print("artifacthub.io/images matches the chart")
