from flask import Flask, request, jsonify, send_from_directory
import face_recognition
import os

app = Flask(__name__)
UPLOAD_FOLDER = os.path.join(os.getcwd(), 'uploads')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # Limit file size to 16MB

# Ensure upload folders exist
os.makedirs(os.path.join(UPLOAD_FOLDER, 'faces'), exist_ok=True)

@app.before_request
def log_request_info():
    print(f"Incoming request: {request.method} {request.path}")

@app.route('/verify_face', methods=['POST'])
def verify_face():
    print("✅ /verify_face route was hit")

    live_file = request.files.get('live')
    stored_file = request.files.get('stored')

    if not live_file or not stored_file:
        print("❌ One or both files missing")
        return jsonify({'error': 'Missing images'}), 400

    # Debug: Check headers and filenames
    print(f"Live file: {live_file.filename}, content_type={live_file.content_type}")
    print(f"Stored file: {stored_file.filename}, content_type={stored_file.content_type}")

    try:
        # Save uploaded files temporarily for verification
        live_path = os.path.join(UPLOAD_FOLDER, 'saved_live.jpg')
        stored_path = os.path.join(UPLOAD_FOLDER, 'saved_stored.jpg')

        live_file.save(live_path)
        stored_file.save(stored_path)

        print(f"📂 Saved {live_path} ({os.path.getsize(live_path)} bytes)")
        print(f"📂 Saved {stored_path} ({os.path.getsize(stored_path)} bytes)")

        # Load and encode both images
        live_image = face_recognition.load_image_file(live_path)
        stored_image = face_recognition.load_image_file(stored_path)

        live_encodings = face_recognition.face_encodings(live_image)
        stored_encodings = face_recognition.face_encodings(stored_image)

        if not live_encodings or not stored_encodings:
            print("❗ No face detected in one or both images")
            return jsonify({
                'match': False,
                'confidence': 0,
                'threshold': 0,
                'message': 'No face detected in one or both images'
            })

        live_encoding = live_encodings[0]
        stored_encoding = stored_encodings[0]

        # Compare faces
        distance = face_recognition.face_distance([stored_encoding], live_encoding)[0]
        threshold = 0.6
        match = distance <= threshold
        confidence = round(max(0, 1 - distance), 4)

        print(f"🔍 Face distance: {distance}, Confidence: {confidence}, Match: {match}")

        return jsonify({
            'match': bool(match),
            'confidence': float(confidence),
            'threshold': float(threshold)
        })

    except Exception as e:
        print(f"❌ Error during verification: {e}")
        return jsonify({'error': str(e)}), 500

# ✅ This route allows downloading images like /uploads/faces/EMP1.jpg
@app.route('/uploads/faces/<filename>')
def uploaded_file(filename):
    return send_from_directory(os.path.join(UPLOAD_FOLDER, 'faces'), filename)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
