import argparse
import subprocess
import json
import sys

def check(condition, message):
    if not condition:
        print(message)
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", help="Expected target architecture")
    parser.add_argument("--winsdk-version", help="Expected Windows SDK version")
    parser.add_argument("--compiler-version", help="Expected compiler version")
    parser.add_argument("--compiler", help="Expected compiler string")
    args = parser.parse_args()

    input_text = sys.stdin.read()
    print(f"CHECK:\n{input_text}")
    output = json.loads(input_text)
    check(output["target"] == args.target, f"Target architecture mismatch. Expected: {args.target}, Actual: {output['target']}")
    check(output["compiler"] == args.compiler, f"Compiler mismatch. Expected: {args.compiler}, Actual: {output['compiler']}")
    check(output["compiler_version"] == args.compiler_version, f"Compiler version mismatch. Expected: {args.compiler_version}, Actual: {output['compiler_version']}")
    check(output["winsdk_version"] == args.winsdk_version, f"Windows SDK version mismatch. Expected: {args.winsdk_version}, Actual: {output['winsdk_version']}")
    print("CHECK PASSED")

if __name__ == "__main__":
    main()
