import React, { useEffect, useState } from "react";
import { useApi } from "../../apiRequest";
import { Container, Spinner } from "react-bootstrap";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";

export default function ReportProducerStatistics() {
  const { apiRequest } = useApi();
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const prevTitle = document.title;
    document.title = "Отчёт: Производители по регионам";
    return () => (document.title = prevTitle);
  }, []);

  useEffect(() => {
    const fetchReport = async () => {
      try {
        const resp = await apiRequest("/report/producer_subject_statistics", "GET");
        if (resp.success) {
          setData(resp.data.report || []);
        } else {
          console.error(resp.message);
        }
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    fetchReport();
  }, []);

  const handlePrint = () => window.print();

  if (loading) {
    return (
      <Container className="text-center mt-5">
        <Spinner animation="border" /> Загрузка...
      </Container>
    );
  }

  return (
    <div className="print-container">
      <Container className="no-print-container" style={{ padding: "24px" }}>
        <button
          onClick={handlePrint}
          style={{
            position: "fixed",
            bottom: "24px",
            right: "24px",
            background: "#007bff",
            color: "white",
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

        <h1 style={{ fontSize: "24px", fontWeight: "bold", marginBottom: "16px" }}>
          Производители по регионам
        </h1>

        <p style={{ fontSize: "16px", color: "#555", marginBottom: "20px" }}>
          Сгенерирован автоматически из базы данных
        </p>

        {/* Гистограмма */}
        <div style={{ width: "100%", height: "400px", marginBottom: "32px" }}>
          <ResponsiveContainer width="100%" height="100%">
            <BarChart
              data={data}
              margin={{ top: 20, right: 30, left: 20, bottom: 50 }}
            >
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="subject" angle={-30} textAnchor="end" height={70} />
              <YAxis />
              <Tooltip />
              <Legend verticalAlign="top" />
              <Bar
                dataKey="producers_quantity"
                fill="#4caf50"
                name="Количество производителей"
              />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Отдельный блок для таблицы */}
        <div style={{ marginTop: "32px" }}>
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr style={{ background: "#f2f2f2" }}>
                <th style={thTdStyle}>Регион</th>
                <th style={thTdStyle}>Количество производителей</th>
                <th style={thTdStyle}>Список производителей</th>
              </tr>
            </thead>
            <tbody>
              {data.map((row) => (
                <tr key={row.number}>
                  <td style={thTdStyle}>{row.subject}</td>
                  <td style={thTdStyle}>{row.producers_quantity}</td>
                  <td style={thTdStyle}>{row.producer_name}</td>
                </tr>
              ))}
            </tbody>
          </table>
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
            table {
              page-break-inside: avoid;
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
