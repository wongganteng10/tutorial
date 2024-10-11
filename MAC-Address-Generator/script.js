function generateMACAddress() {
    const hexDigits = "0123456789ABCDEF";
    let macAddress = "";

    for (let i = 0; i < 6; i++) {
        macAddress += hexDigits.charAt(Math.floor(Math.random() * 16));
        macAddress += hexDigits.charAt(Math.floor(Math.random() * 16));
        if (i !== 5) macAddress += ":";
    }

    return macAddress;
}

document.getElementById("generate-btn").addEventListener("click", function() {
    const macAddress = generateMACAddress();
    document.getElementById("mac-address").value = macAddress;
});
