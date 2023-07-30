from flask import Flask, jsonify

app = Flask(__name__)

data = {"message": "hello"}

@app.route('/hello', methods=['GET'])
def get_msg():
    return jsonify(data)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
