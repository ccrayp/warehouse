import React, { useEffect, useState } from "react";
import { useApi } from "../../apiRequest.js";
import PrintUserInfo from "./PrintUserInfo.jsx";
import { Container } from "react-bootstrap";

export default function ReportExpiredBatches() {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const { apiRequest } = useApi();

  // Меняем заголовок вкладки
  useEffect(() => {
    const prevTitle = document.title;
    document.title = "Отчёт: Просроченные партии";

    return () => {
      document.title = prevTitle;
    };
  }, []);

  // Загружаем отчёт
  useEffect(() => {
    const fetchReport = async () => {
      try {
        const response = await apiRequest(`/report/expired_batches`, "GET", null, {
          Authorization: `Bearer ${localStorage.getItem("access_token")}`,
        });

        if (response.success) {
          setData(response.data.report || []);
        } else {
          console.error(response.message || "Ошибка получения отчета");
        }
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    fetchReport();
  }, []);

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="print-container">
      <Container className="no-print-container">
        <div style={{ padding: "24px", fontFamily: "Arial, sans-serif", lineHeight: 1.5 }}>
          
          {/* Кнопка печати */}
          <button
            onClick={handlePrint}
            style={{
              position: "fixed",
              bottom: "24px",
              right: "24px",
              background: "#007bff",
              color: "#fff",
              border: "none",
              padding: "12px 18px",
              fontSize: "16px",
              borderRadius: "8px",
              cursor: "pointer",
              boxShadow: "0 4px 10px rgba(0,0,0,0.2)",
              zIndex: 999,
            }}
          >
            <i className="fa-solid fa-file" style={{ marginRight: "8px" }}></i>
            Сохранить
          </button>

          {/* Заголовок */}
          <h1 style={{ fontSize: "24px", fontWeight: "bold", marginBottom: "12px" }}>
            Отчет по просроченным партиям
          </h1>

          <p style={{ fontSize: "16px", color: "#555", marginBottom: "20px" }}>
            Сгенерирован автоматически из базы данных
          </p>

          {/* Таблица */}
          {loading ? (
            <p>Загрузка...</p>
          ) : (
            <table style={{ width: "100%", borderCollapse: "collapse", marginBottom: "24px" }}>
              <thead>
                <tr style={{ background: "#f2f2f2" }}>
                  <th style={thTdStyle}>№</th>
                  <th style={thTdStyle}>ID партии</th>
                  <th style={thTdStyle}>Название продукта</th>
                  <th style={thTdStyle}>Дата истечения срока</th>
                  <th style={thTdStyle}>Остаток</th>
                </tr>
              </thead>

              <tbody>
                {data.map((row, index) => (
                  <tr key={index}>
                    <td style={thTdStyle}>{row.number}</td>
                    <td style={thTdStyle}>{row.batch_id}</td>
                    <td style={thTdStyle}>{row.product_name}</td>
                    <td style={thTdStyle}>{new Date(row.expiration_date).toLocaleDateString()}</td>
                    <td style={thTdStyle}>{row.remaining_quantity}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}

          {/* Информация о текущем пользователе */}
          <PrintUserInfo />
        </div>
      </Container>

      {/* CSS для печати */}
      <style>
        {`
          @media print {
            .no-print-container {
              padding: 0 !important;
              margin: 0 !important;
              width: 100% !important;
              max-width: 100% !important;
            }

            button {
              display: none !important;
            }
          }
        `}
      </style>
    </div>
  );
}

const thTdStyle = {
  border: "1px solid #333",
  padding: "8px 12px",
  textAlign: "left",
};
