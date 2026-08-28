const testSignup = async () => {
    try {
        const response = await fetch('http://localhost:5005/api/auth/signup', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                name: "chandan",
                email: "chandans@gmail.com",
                phone: "75544123698",
                password: "chandan@0987",
                role: "customer"
            })
        });
        const data = await response.json();
        if (response.ok) {
            console.log('Success:', response.status, data);
        } else {
            console.log('Error:', response.status, JSON.stringify(data, null, 2));
        }
    } catch (error) {
        console.log('Error:', error.message);
    }
};

testSignup();
