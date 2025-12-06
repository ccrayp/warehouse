// src/App.jsx
import { useEffect, useState } from "react";

const API_URL = "http://localhost:8080/api/products?limit=100&offset=0";
const TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6InZhbGVudGluX2FkbWluIiwicm9sZSI6ImFkbWluIiwiZXhwIjoxNzY1MDE0MjY4fQ.EIcRqKgCogSYDvBPVCCTR6PzRAVJBOBH5UVBCQwAJYs";

function App() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadProducts() {
      try {
        const response = await fetch(API_URL, {
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${TOKEN}`,
          },
        });

        const data = await response.json();

        if (!data.success) {
          console.error("Ошибка API:", data.message);
          setProducts([]);
          return;
        }

        setProducts(data.data.products);
      } catch (err) {
        console.error("Ошибка загрузки товаров:", err);
      } finally {
        setLoading(false);
      }
    }

    loadProducts();
  }, []);

  return (
    <div style={{ fontFamily: "Arial, sans-serif", backgroundColor: "#f7f7f7", padding: "20px" }}>
      <h1>Товары</h1>
      {loading ? (
        <p>Загрузка...</p>
      ) : (
        <div style={{ display: "flex", flexWrap: "wrap", gap: "20px" }}>
          {products.map((product) => {
            const imgUrl = product.image_url.startsWith("/")
              ? "http://localhost:8080" + product.image_url
              : product.image_url;

            return (
              <div
                key={product.id}
                style={{
                  backgroundColor: "#fff",
                  borderRadius: "8px",
                  boxShadow: "0 2px 6px rgba(0,0,0,0.1)",
                  width: "200px",
                  padding: "10px",
                  textAlign: "center",
                }}
              >
                <img
                  src={imgUrl}
                  alt={product.name}
                  style={{ width: "100%", height: "150px", objectFit: "contain", borderRadius: "4px", marginBottom: "10px" }}
                />
                <h3 style={{ fontSize: "16px", margin: 0 }}>{product.name}</h3>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

export default App;
