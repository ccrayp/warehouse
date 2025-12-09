import React, { useEffect, useState } from "react";
import { useApi } from "../../apiRequest.js";
import PrintUserInfo from "./PrintUserInfo.jsx";
import { Container } from "react-bootstrap";

export default function ReportDocumentsByEmployee() {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const { apiRequest } = useApi();

  useEffect(() => {
    const prevTitle = document.title;
    document.title = "Отчёт: Документы по сотрудникам";

    return () => {
      document.title = prevTitle;
    };
  }, []);

  // Загружаем отчёт
  useEffect(() => {
    const fetchReport = async () => {
      try {
        const response = await apiRequest(`/report/documents_by_employee`, "GET");

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
            Отчет по документам сотрудников
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
                  <th style={thTdStyle}>№ сотрудника</th>
                  <th style={thTdStyle}>Сотрудник</th>
                  <th style={thTdStyle}>Должность</th>
                  <th style={thTdStyle}>Категория документа</th>
                  <th style={thTdStyle}>Количество документов</th>
                </tr>
              </thead>

              <tbody>
                {data.map((row, index) => (
                  <tr key={index}>
                    <td style={thTdStyle}>{row.employee_number}</td>
                    <td style={thTdStyle}>{row.employee}</td>
                    <td style={thTdStyle}>{row.position}</td>
                    <td style={thTdStyle}>{row.document_category}</td>
                    <td style={thTdStyle}>{row.documents}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
          <PrintUserInfo />
        </div>
      </Container>
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
