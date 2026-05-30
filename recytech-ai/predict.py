import tensorflow as tf
import numpy as np
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input

MODEL_PATH = "recytech_cnn_model.keras"
IMAGE_PATH = "sample.jpg"

model = tf.keras.models.load_model(MODEL_PATH)

model.summary()

with open("class_names.txt", "r") as f:
    class_names = [line.strip() for line in f.readlines()]

img = tf.keras.utils.load_img(
    IMAGE_PATH,
    target_size=(224, 224)
)

img_array = tf.keras.utils.img_to_array(img)
img_array = np.expand_dims(img_array, axis=0)

img_array = preprocess_input(img_array)

prediction = model.predict(img_array)
score = prediction[0]

predicted_class = class_names[np.argmax(score)]
confidence = 100 * np.max(score)

print("Class names:", class_names)
print("Raw prediction:", prediction[0])
print("Highest index:", np.argmax(prediction[0]))

print(f"Predicted class: {predicted_class}")
print(f"Confidence: {confidence:.2f}%")
print(class_names)
print(prediction[0])