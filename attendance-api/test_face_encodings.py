import face_recognition

def check_face(image_path):
    try:
        image = face_recognition.load_image_file(image_path)
        encodings = face_recognition.face_encodings(image)
        if encodings:
            print(f"✅ Face found in: {image_path}")
            return encodings[0]
        else:
            print(f"❌ No face found in: {image_path}")
            return None
    except Exception as e:
        print(f"⚠️ Error loading {image_path}: {e}")
        return None

check_face("saved_live.jpg")
check_face("saved_stored.jpg")

