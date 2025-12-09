import { useEffect, useState } from "react";
import { Container, Card, Spinner, Row, Col, Carousel } from "react-bootstrap";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faBox, faBuilding, faUsers, faTags } from "@fortawesome/free-solid-svg-icons";
import { apiHost } from "../utils";

const STATS_URL = `${apiHost}/info/homepage`;
const PAGE_SIZE = 4; // 4 товара на слайд

function Home() {
  const [products, setProducts] = useState([]);
  const [loadingProducts, setLoadingProducts] = useState(true);
  const [stats, setStats] = useState({ products: 0, producers: 0, categories: 0, employees: 0 });

  async function loadProducts() {
    setLoadingProducts(true);
    try {
      const response = await fetch(`${apiHost}/products?limit=50&offset=0`, {
        headers: { "Content-Type": "application/json" },
      });
      const data = await response.json();
      if (!data.success) {
        setProducts([]);
        return;
      }
      setProducts(data.data.products);
    } catch (err) {
      console.error("Ошибка загрузки товаров:", err);
    } finally {
      setLoadingProducts(false);
    }
  }

  async function loadStats() {
    try {
      const response = await fetch(STATS_URL, { headers: { "Content-Type": "application/json" } });
      const data = await response.json();
      if (!data.success) return;
      setStats({
        products: data.data.prodcut ?? 0,
        producers: data.data.producer ?? 0,
        categories: data.data.categoris ?? 0,
        employees: data.data.employee ?? 0,
      });
    } catch (err) {
      console.error("Ошибка загрузки статистики:", err);
    }
  }

  useEffect(() => {
    loadProducts();
    loadStats();
  }, []);

  const slides = [];
  for (let i = 0; i < products.length; i += PAGE_SIZE) {
    slides.push(products.slice(i, i + PAGE_SIZE));
  }

  return (
    <div>
      <div
        style={{
          width: "100%",
          height: "400px",
          overflow: "hidden",
          textAlign: "center",
          backgroundColor: "#f0f8ff",
        }}
      >
        <img
          src="/homepage.jpg"
          alt="Фон"
          style={{ width: "100%", height: "100%", objectFit: "cover", objectPosition: "center" }}
        />
      </div>

      <Container className="py-4">
        <Row className="g-3 mb-4 text-center">
          <Col md={3} sm={6}>
            <Card className="p-3 shadow-sm">
              <FontAwesomeIcon icon={faBox} size="2x" className="mb-2" />
              <h5>Товаров</h5>
              <div className="fs-4">{stats.products}</div>
            </Card>
          </Col>
          <Col md={3} sm={6}>
            <Card className="p-3 shadow-sm">
              <FontAwesomeIcon icon={faBuilding} size="2x" className="mb-2" />
              <h5>Поставщиков</h5>
              <div className="fs-4">{stats.producers}</div>
            </Card>
          </Col>
          <Col md={3} sm={6}>
            <Card className="p-3 shadow-sm">
              <FontAwesomeIcon icon={faTags} size="2x" className="mb-2" />
              <h5>Категорий</h5>
              <div className="fs-4">{stats.categories}</div>
            </Card>
          </Col>
          <Col md={3} sm={6}>
            <Card className="p-3 shadow-sm">
              <FontAwesomeIcon icon={faUsers} size="2x" className="mb-2" />
              <h5>Сотрудников</h5>
              <div className="fs-4">{stats.employees}</div>
            </Card>
          </Col>
        </Row>

        {/* Товары */}
        <h2 className="mb-4">Товары на складе</h2>

        {loadingProducts ? (
          <div className="d-flex justify-content-center py-5">
            <Spinner animation="border" />
          </div>
        ) : (
          <Carousel indicators={true} nextIcon={null} prevIcon={null}>
            {slides.map((slide, idx) => (
              <Carousel.Item key={idx}>
                <Row className="g-4 justify-content-center">
                  {slide.map((product) => {
                    const imgUrl = product.image_url?.startsWith("/")
                      ? apiHost + product.image_url
                      : product.image_url;
                    return (
                      <Col key={product.id} xs={12} sm={6} md={3}>
                        <Card
                          className="h-100 shadow-sm text-center"
                        >
                          <Card.Img
                            variant="top"
                            src={imgUrl}
                            alt={product.name}
                            style={{ height: "200px", objectFit: "contain", padding: "10px" }}
                          />
                          <Card.Body>
                            <Card.Title className="fs-5">{product.name}</Card.Title>
                          </Card.Body>
                        </Card>
                      </Col>
                    );
                  })}
                </Row>
              </Carousel.Item>
            ))}
          </Carousel>
        )}
      </Container>
    </div>
  );
}

export default Home;
