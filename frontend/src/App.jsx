// App.jsx
import { useState } from "react";
import styled from "styled-components";
import "bootstrap/dist/css/bootstrap.min.css";
import { BrowserRouter, Routes, Route } from "react-router-dom";

import { AuthProvider } from "./AuthContext";
import Header from "./common/Header";
import Footer from "./common/Footer";
import Sidebar from "./common/Sidebar";
import NotFound from "./common/NotFound";

import Home from "./pages/Home";
import Login from "./pages/Login";
import Profile from "./pages/Profile";
import AuditLogs from "./pages/AuditLogs";

import Reports from "./pages/Reports";
import ReportBatches from "./pages/Reports/ReportBatches";
import ReportDocumentsByEmployee from "./pages/Reports/DocumentsByEmployee";
import ReportEmployees from "./pages/Reports/Employees";
import ReportExpiredBatches from "./pages/Reports/ExpiredBatches";
import ReportGrants from "./pages/Reports/Grants";

export const ContentWrapper = styled.div.attrs({
  className: "content-wrapper"
})`
  margin-top: 80px;
  min-height: calc(100vh - 60px);
`;

export default function App() {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const toggleSidebar = () => setSidebarOpen(!sidebarOpen);

  return (
    <AuthProvider>
      <BrowserRouter>
        <Header onToggleSidebar={toggleSidebar} />
        <ContentWrapper>
          <Sidebar show={sidebarOpen} onHide={() => setSidebarOpen(false)} />
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="*" element={<NotFound />} />
            <Route path="/login" element={<Login />} />
            <Route path="/profile" element={<Profile />} />
            <Route path="/audit_log" element={<AuditLogs />} />
            <Route path="/report" element={<Reports />} />

            <Route path="/reports/report_batches" element={<ReportBatches />} />
            <Route path="/reports/report_documents_by_employee" element={<ReportDocumentsByEmployee />} />
            <Route path="/reports/report_employees" element={<ReportEmployees />} />
            <Route path="/reports/report_expired_batches" element={<ReportExpiredBatches />} />
            <Route path="/reports/report_grants" element={<ReportGrants />} />

          </Routes>
        </ContentWrapper>
        <Footer />
      </BrowserRouter>
    </AuthProvider>
  );
}
