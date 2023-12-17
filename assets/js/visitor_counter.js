// API endpoint is created after API is deployed in AWS API Gateway
fetch('https://qu70rihi13.execute-api.us-east-1.amazonaws.com/get-visitor-count')
    .then(response => {
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        return response.json();
    })
    .then(data => {
        // Handle the data received from the API
        console.log('Data from API:', data);
        // Update the visitorCount element with the received count
        document.getElementById('visitorCount').textContent = data;
    })
    .catch(error => {
        // Handle errors that occurred during fetch
        console.error('Fetch error:', error);
    });