import React, { useEffect, useState } from "react";
import { useApi } from "../../apiRequest";
import { Container, Spinner } from "react-bootstrap";
import PrintUserInfo from "./PrintUserInfo";
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

export default function ReportTableActivity() {
  const { apiRequest } = useApi();
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const prevTitle = document.title;
    document.title = "Отчёт: Активность по таблицам";
    return () => (document.title = prevTitle);
  }, []);

  useEffect(() => {
    const fetchReport = async () => {
      try {
        const resp = await apiRequest("/report/tables_activity", "GET");
        if (resp.success) {
          const raw = resp.data.report;

          // Группируем по таблицам
          const grouped = {};
          raw.forEach((row) => {
            if (!grouped[row.table_name]) {
              grouped[row.table_name] = { table_name: row.table_name, INSERT: 0, UPDATE: 0, DELETE: 0 };
            }
            grouped[row.table_name][row.action] = row.action_quantity;
          });

          setData(Object.values(grouped));
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
          Активность по таблицам
        </h1>

        <p style={{ fontSize: "16px", color: "#555", marginBottom: "20px" }}>
          Сгенерирован автоматически из базы данных
        </p>

        {/* Гистограмма */}
        <div style={{ width: "100%", height: "800px", marginBottom: "32px" }}>
          <ResponsiveContainer width="100%" height="100%">
            <BarChart
              data={data}
              margin={{ top: 20, right: 30, left: 20, bottom: 70 }}
            >
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="table_name" angle={-30} textAnchor="end" height={70} />
              <YAxis />
              <Tooltip />
              <Legend verticalAlign="top" />
              <Bar dataKey="INSERT" fill="#4caf50" />
              <Bar dataKey="UPDATE" fill="#2196f3" />
              <Bar dataKey="DELETE" fill="#f44336" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Таблица для печати */}
        <div style={{ marginTop: "32px" }}>
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr style={{ background: "#f2f2f2" }}>
                <th style={thTdStyle}>Таблица</th>
                <th style={thTdStyle}>INSERT</th>
                <th style={thTdStyle}>UPDATE</th>
                <th style={thTdStyle}>DELETE</th>
              </tr>
            </thead>
            <tbody>
              {data.map((row, idx) => (
                <tr key={idx}>
                  <td style={thTdStyle}>{row.table_name}</td>
                  <td style={thTdStyle}>{row.INSERT}</td>
                  <td style={thTdStyle}>{row.UPDATE}</td>
                  <td style={thTdStyle}>{row.DELETE}</td>
                </tr>
              ))}
            </tbody>
          </table>
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
