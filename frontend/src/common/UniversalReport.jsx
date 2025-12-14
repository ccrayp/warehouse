import React, { useContext, useEffect } from "react";
import { Container } from "react-bootstrap";
import { AuthContext } from "../AuthContext";
import PrintUserInfo from "../pages/Reports/PrintUserInfo";

export default function UniversalReport({ title, columns, rows, section }) {
  const { sections } = useContext(AuthContext);

  const hasAccess =
    sections &&
    sections.some(
      (s) => s.section === section && s.permissions.includes("select")
    );

  useEffect(() => {
    const prev = document.title;
    document.title = `Отчёт: ${title}`;
    return () => (document.title = prev);
  }, [title]);

  const handlePrint = () => window.print();

  if (!sections) {
    return (
      <Container style={{ padding: "40px" }}>
        <h3>Загрузка прав доступа…</h3>
      </Container>
    );
  }

  if (!hasAccess) {
    return (
      <Container style={{ padding: "40px" }}>
        <h2 style={{ color: "darkred" }}>Нет доступа</h2>
        <p style={{ fontSize: "18px" }}>Вы не можете просматривать этот отчёт.</p>
      </Container>
    );
  }

  return (
    <div className="print-container">
      <Container className="no-print-container">
        <div style={{ padding: "24px", fontFamily: "Arial, sans-serif" }}>
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
              zIndex: 999,
            }}
          >
            <i className="fa-solid fa-download" style={{ marginRight: "8px" }}></i>
            Сохранить
          </button>

          <h1 style={{ marginBottom: "16px" }}>{title}</h1>

          <table
            style={{
              width: "100%",
              borderCollapse: "collapse",
              marginBottom: "24px",
            }}
          >
            <thead>
              <tr style={{ background: "#f2f2f2" }}>
                {columns.map((col) => (
                  <th key={col.key} style={thTdStyle}>
                    {col.label}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {rows.map((row, idx) => (
                <tr key={idx}>
                  {columns.map((col) => (
                    <td key={col.key} style={thTdStyle}>
                      {col.format ? col.format(row[col.key]) : row[col.key]}
                    </td>
                  ))}
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
              padding: 0!important;
              margin: 0!important;
              max-width: 100%!important;
            }
            button { display: none !important; }
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