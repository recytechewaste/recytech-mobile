from __future__ import annotations

import argparse
import sys
from pathlib import Path


def load_interpreter(model_path: str):
    try:
        from tensorflow.lite.python.interpreter import Interpreter

        return Interpreter(model_path=model_path), "tensorflow"
    except Exception as tensorflow_error:
        try:
            from tflite_runtime.interpreter import Interpreter

            return Interpreter(model_path=model_path), "tflite_runtime"
        except Exception as runtime_error:
            print("Could not import a TensorFlow Lite interpreter.")
            print(f"tensorflow import error: {tensorflow_error}")
            print(f"tflite_runtime import error: {runtime_error}")
            sys.exit(1)


def print_tensor_details(title: str, details: list[dict]) -> None:
    print(f"\n{title}")
    print("-" * len(title))
    for index, tensor in enumerate(details):
        print(f"{index}:")
        print(f"  name: {tensor.get('name')}")
        print(f"  index: {tensor.get('index')}")
        print(f"  shape: {tensor.get('shape')}")
        print(f"  shape_signature: {tensor.get('shape_signature')}")
        print(f"  dtype: {tensor.get('dtype')}")
        print(f"  quantization: {tensor.get('quantization')}")
        quant_params = tensor.get("quantization_parameters")
        if quant_params:
            print(f"  quantization_parameters: {quant_params}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Inspect TensorFlow Lite input/output tensor details."
    )
    parser.add_argument(
        "model",
        nargs="?",
        default="recytecmobproj/assets/models/recytech_yolov8.tflite",
        help="Path to the .tflite model.",
    )
    args = parser.parse_args()

    model_path = Path(args.model).resolve()
    if not model_path.exists():
        print(f"Model file not found: {model_path}")
        sys.exit(1)

    interpreter, backend = load_interpreter(str(model_path))
    interpreter.allocate_tensors()

    print(f"Interpreter backend: {backend}")
    print(f"Model path: {model_path}")
    print(f"Model size: {model_path.stat().st_size:,} bytes")

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    print_tensor_details("Input tensor details", input_details)
    print_tensor_details("Output tensor details", output_details)

    if input_details:
        first_input = input_details[0]
        print("\nSummary")
        print("-------")
        print(f"input shape: {first_input.get('shape')}")
        print(f"input dtype: {first_input.get('dtype')}")

    if output_details:
        first_output = output_details[0]
        print(f"output shape: {first_output.get('shape')}")
        print(f"output dtype: {first_output.get('dtype')}")


if __name__ == "__main__":
    main()
