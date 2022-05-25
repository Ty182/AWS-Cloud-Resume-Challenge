function updateCount() {
    // API endpoint, returns website visitor count
    fetch("https://9keboyf993.execute-api.us-east-1.amazonaws.com/prod")
        .then(response => response.text())
        .then((body) => {
            // "counter" is used to show the visitor count in the HTML 
            document.getElementById("counter").innerHTML = body
        })
        .catch(function (error) {
            console.log(error);
        });
}  