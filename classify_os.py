import json
import pandas as pd
import numpy as np
import sys
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import accuracy_score

def load_data(input_file):
    with open(input_file, 'r', encoding='utf-8') as f:
        data = [json.loads(line) for line in f]
    return pd.DataFrame(data)

def preprocess_data(df):
    # Удаление дубликатов по IP и fingerprint
    if 'js_fingerprint.fingerprint' in df.columns:
        df.drop_duplicates(subset=['ip', 'js_fingerprint.fingerprint'], inplace=True)
    else:
        df.drop_duplicates(subset=['ip'], inplace=True)
    
    # Выбор полезных признаков
    df['tls_version'] = df['tls'].apply(lambda x: x.get('tls_version_negotiated', None))
    df['num_ciphers'] = df['tls'].apply(lambda x: len(x.get('ciphers', [])))
    df['num_extensions'] = df['tls'].apply(lambda x: len(x.get('extensions', [])))
    df['http2_window_size'] = df['http2'].apply(lambda x: x.get('sent_frames', [{}])[0].get('length', 0))
    df['tcp_ttl'] = df['tcpip'].apply(lambda x: x.get('ip', {}).get('ttl', None))
    df['os_predicted'] = df['os_prediction'].apply(lambda x: x.get('highest', 'Unknown'))
    
    # Убираем строки с пропущенными значениями
    df.dropna(inplace=True)
    return df[['ip', 'tls_version', 'num_ciphers', 'num_extensions', 'http2_window_size', 'tcp_ttl', 'os_predicted']]

def encode_and_train(df):
    le = LabelEncoder()
    df['tls_version'] = le.fit_transform(df['tls_version'])
    df['os_predicted'] = le.fit_transform(df['os_predicted'])
    
    X = df.drop(columns=['os_predicted', 'ip'])
    y = df['os_predicted']
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    y_pred = model.predict(X_test)
    print(f'Accuracy: {accuracy_score(y_test, y_pred)}')
    
    return model, le

def classify_new_data(model, le, df):
    X = df.drop(columns=['os_predicted', 'ip'])
    predictions = model.predict(X)
    probabilities = model.predict_proba(X).max(axis=1)
    df['predicted_os'] = le.inverse_transform(predictions)
    df['confidence'] = probabilities
    return df[['ip', 'predicted_os', 'confidence']]

def main(input_file, output_file):
    df = load_data(input_file)
    df = preprocess_data(df)
    model, le = encode_and_train(df)
    results = classify_new_data(model, le, df)
    
    results.to_json(output_file, orient='records', indent=4)
    print(f'Results saved to {output_file}')

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python classify_os.py input.json output.json")
    else:
        main(sys.argv[1], sys.argv[2])
