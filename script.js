// Global variables
let model, webcam, labelContainer, maxPredictions;
const modelURL = "./my_model/model.json";
const metadataURL = "./my_model/metadata.json";

// Disease information database
const diseaseDatabase = {
    "healthy": {
        description: "The plant appears healthy with no signs of disease.",
        treatment: "Continue regular plant care and monitoring."
    },
    "powdery_mildew": {
        description: "White powdery spots on leaves and stems caused by fungal infection.",
        treatment: "Apply sulfur, potassium bicarbonate, or neem oil. Improve air circulation."
    },
    "leaf_spot": {
        description: "Circular brown or black spots on leaves caused by fungi or bacteria.",
        treatment: "Remove affected leaves. Apply copper-based fungicides."
    }
    // Add more diseases as needed based on your model's classes
};

// Initialize the model
async function loadModel() {
    model = await tmImage.load(modelURL, metadataURL);
    maxPredictions = model.getTotalClasses();
    
    // Initialize label container
    labelContainer = document.getElementById("label-container");
    labelContainer.innerHTML = ''; // Clear any existing content
    
    console.log("Model loaded successfully");
}

// Webcam functions
async function initWebcam() {
    try {
        // Load model if not already loaded
        if (!model) await loadModel();
        
        // Set up webcam
        const flip = true; // whether to flip the webcam
        webcam = new tmImage.Webcam(400, 400, flip); // width, height, flip
        await webcam.setup(); // request access to the webcam
        await webcam.play();
        
        // Append elements to the DOM
        document.getElementById("webcam-container").innerHTML = '';
        document.getElementById("webcam-container").appendChild(webcam.canvas);
        
        // Show stop button
        document.getElementById("stop-webcam").style.display = 'inline-block';
        
        // Start prediction loop
        window.requestAnimationFrame(webcamLoop);
        
    } catch (error) {
        console.error("Error initializing webcam:", error);
        alert("Could not access the webcam. Please check permissions.");
    }
}

async function webcamLoop() {
    if (webcam) {
        webcam.update(); // update the webcam frame
        await predictWebcam();
        window.requestAnimationFrame(webcamLoop);
    }
}

async function predictWebcam() {
    if (webcam && model) {
        const prediction = await model.predict(webcam.canvas);
        displayPredictions(prediction);
    }
}

function stopWebcam() {
    if (webcam) {
        webcam.stop();
        document.getElementById("webcam-container").innerHTML = '<p>Camera stopped</p>';
        document.getElementById("stop-webcam").style.display = 'none';
        webcam = null;
    }
}

// Image upload functions
document.getElementById('image-upload').addEventListener('change', function(e) {
    const file = e.target.files[0];
    if (file) {
        const reader = new FileReader();
        reader.onload = function(event) {
            const img = document.getElementById('uploaded-image');
            img.src = event.target.result;
            img.style.display = 'block';
            document.getElementById('predict-upload').disabled = false;
        };
        reader.readAsDataURL(file);
    }
});

async function predictUpload() {
    const image = document.getElementById('uploaded-image');
    if (image && model) {
        const prediction = await model.predict(image);
        displayPredictions(prediction);
    }
}

// Display predictions
function displayPredictions(predictions) {
    // Clear previous results
    labelContainer.innerHTML = '';
    
    // Sort predictions by probability
    const sortedPredictions = Array.from(predictions)
        .sort((a, b) => b.probability - a.probability);
    
    // Display each prediction
    sortedPredictions.forEach(pred => {
        const predItem = document.createElement('div');
        predItem.className = 'prediction-item';
        
        const confidencePercent = Math.round(pred.probability * 100);
        
        predItem.innerHTML = `
            <div>
                <strong>${formatLabel(pred.className)}</strong>
                <div>${confidencePercent}% confidence</div>
            </div>
            <div class="confidence-bar">
                <div class="confidence-level" style="width: ${confidencePercent}%"></div>
            </div>
        `;
        
        labelContainer.appendChild(predItem);
    });
    
    // Display disease information for top prediction
    displayDiseaseInfo(sortedPredictions[0].className);
}

// Format label for display (convert underscores to spaces and capitalize)
function formatLabel(label) {
    return label.split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');
}

// Display disease information
function displayDiseaseInfo(diseaseKey) {
    const diseaseInfo = document.getElementById('disease-info');
    const disease = diseaseDatabase[diseaseKey] || diseaseDatabase['healthy'];
    
    diseaseInfo.innerHTML = `
        <h3>About ${formatLabel(diseaseKey)}</h3>
        <p><strong>Description:</strong> ${disease.description}</p>
        <p><strong>Recommended Treatment:</strong> ${disease.treatment}</p>
    `;
}

// Initialize the model when the page loads
window.onload = function() {
    loadModel();
};